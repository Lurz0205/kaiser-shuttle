/**
 * Kaiser Shuttle - Authoritative WebSocket Game Server
 * Zero-dependency (only 'ws'), runs on Render.com, Koyeb, Glitch, Railway, or VPS.
 */

const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(`Kaiser Shuttle Game Server is ONLINE!\nActive Rooms: ${Object.keys(rooms).length}\nConnected Clients: ${wss.clients.size}\n`);
});

const wss = new WebSocket.Server({ server });

const rooms = {};

// Court Geometry Constants
const NET_X = 640.0;
const NET_TOP_Y = 440.0; // 550 - 110
const FLOOR_Y = 550.0;
const LEFT_OUT_X = 140.0;
const RIGHT_OUT_X = 1140.0;
const SHORT_SERVICE_LEFT = 495.0;
const SHORT_SERVICE_RIGHT = 785.0;

function generateRoomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    let code = '';
    for (let i = 0; i < 4; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}

function broadcastToRoom(room, data) {
    const msg = JSON.stringify(data);
    if (room.p1 && room.p1.readyState === WebSocket.OPEN) {
        room.p1.send(msg);
    }
    if (room.p2 && room.p2.readyState === WebSocket.OPEN) {
        room.p2.send(msg);
    }
}

function sendTo(ws, data) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(data));
    }
}

wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.roomCode = null;
    ws.playerRole = null; // 'p1' or 'p2'

    ws.on('pong', () => { ws.isAlive = true; });

    ws.on('message', (message) => {
        let data;
        try {
            data = JSON.parse(message);
        } catch (e) {
            return;
        }

        const type = data.t || data.type;

        switch (type) {
            case 'ping': {
                sendTo(ws, { t: 'pong', ts: data.ts });
                break;
            }

            case 'create_room': {
                let code = (data.code || generateRoomCode()).toUpperCase().trim();
                while (rooms[code]) {
                    code = generateRoomCode();
                }

                const room = {
                    code: code,
                    p1: ws,
                    p2: null,
                    p1_char: data.char || 'nishikawa',
                    p2_char: 'wall',
                    pts: data.pts || 11,
                    sets: data.sets || 1,
                    status: 'waiting', // waiting, ready, countdown, playing, point_over, match_over
                    p1_pts: 0,
                    p2_pts: 0,
                    p1_sets: 0,
                    p2_sets: 0,
                    current_set: 0,
                    server_player: 'p1', // 'p1' or 'p2'
                    
                    // Positions (P1 on Left 20-620, P2 on Right 660-1260 in authoritative frame)
                    p1_pos: { x: 390.0, y: FLOOR_Y, vx: 0, vy: 0, f: 1, sw: false, dv: false },
                    p2_pos: { x: 890.0, y: FLOOR_Y, vx: 0, vy: 0, f: -1, sw: false, dv: false },

                    // Shuttlecock
                    ball: {
                        x: 390.0,
                        y: FLOOR_Y - 35.0,
                        vx: 0,
                        vy: 0,
                        active: false,
                        serve: true,
                        last_hitter: 'p1',
                        flight_time: 0,
                        flight_duration: 1.0,
                        from_x: 390.0,
                        from_y: FLOOR_Y - 35.0,
                        target_x: 890.0,
                        target_y: FLOOR_Y,
                        shot_type: 'clear',
                        is_smash: false
                    },

                    countdown_timer: 0,
                    point_reset_timer: 0
                };

                rooms[code] = room;
                ws.roomCode = code;
                ws.playerRole = 'p1';

                sendTo(ws, {
                    t: 'room_created',
                    code: code,
                    role: 'p1',
                    pts: room.pts,
                    sets: room.sets
                });
                console.log(`[ROOM CREATED] Code: ${code}`);
                break;
            }

            case 'join_room': {
                const code = (data.code || '').toUpperCase().trim();
                const room = rooms[code];

                if (!room) {
                    sendTo(ws, { t: 'error', msg: 'Không tìm thấy phòng ' + code });
                    return;
                }
                if (room.p2 && room.p2.readyState === WebSocket.OPEN) {
                    sendTo(ws, { t: 'error', msg: 'Phòng ' + code + ' đã đủ người!' });
                    return;
                }

                room.p2 = ws;
                room.p2_char = data.char || 'fuji';
                room.status = 'ready';
                ws.roomCode = code;
                ws.playerRole = 'p2';

                // Notify Guest
                sendTo(ws, {
                    t: 'room_joined',
                    code: code,
                    role: 'p2',
                    host_char: room.p1_char,
                    guest_char: room.p2_char,
                    pts: room.pts,
                    sets: room.sets
                });

                // Notify Host
                sendTo(room.p1, {
                    t: 'guest_joined',
                    code: code,
                    guest_char: room.p2_char
                });

                console.log(`[ROOM JOINED] Code: ${code} - Player 2 entered`);
                break;
            }

            case 'start_match': {
                if (ws.playerRole !== 'p1') return;
                const room = rooms[ws.roomCode];
                if (!room || !room.p2) return;

                room.pts = data.pts || room.pts;
                room.sets = data.sets || room.sets;
                room.status = 'countdown';
                room.countdown_timer = 3.0;

                broadcastToRoom(room, {
                    t: 'countdown_start',
                    seconds: 3,
                    pts: room.pts,
                    sets: room.sets,
                    p1_char: room.p1_char,
                    p2_char: room.p2_char
                });
                break;
            }

            case 'player_input': {
                const room = rooms[ws.roomCode];
                if (!room || room.status !== 'playing') return;

                if (ws.playerRole === 'p1') {
                    // P1 is naturally on the left
                    room.p1_pos = {
                        x: Number(data.x) || room.p1_pos.x,
                        y: Number(data.y) || room.p1_pos.y,
                        vx: Number(data.vx) || 0,
                        vy: Number(data.vy) || 0,
                        f: 1.0,
                        sw: Boolean(data.sw),
                        dv: Boolean(data.dv)
                    };
                } else if (ws.playerRole === 'p2') {
                    // P2 controls their local left, so server mirrors to authoritative right (1280 - x)
                    room.p2_pos = {
                        x: 1280.0 - (Number(data.x) || (1280.0 - room.p2_pos.x)),
                        y: Number(data.y) || room.p2_pos.y,
                        vx: -(Number(data.vx) || 0),
                        vy: Number(data.vy) || 0,
                        f: -1.0,
                        sw: Boolean(data.sw),
                        dv: Boolean(data.dv)
                    };
                }
                break;
            }

            case 'serve': {
                const room = rooms[ws.roomCode];
                if (!room || room.status !== 'playing') return;
                if (!room.ball.serve) return;

                const shotType = data.shot_type || 'clear';
                if (room.server_player === 'p1' && ws.playerRole === 'p1') {
                    // P1 serves from 390 towards right
                    const fromPt = { x: room.p1_pos.x + 30.0, y: FLOOR_Y - 35.0 };
                    const targetX = shotType === 'clear' ? 1070.0 : 815.0;
                    launchShuttle(room, fromPt, { x: targetX, y: FLOOR_Y }, shotType, 'p1', true);
                } else if (room.server_player === 'p2' && ws.playerRole === 'p2') {
                    // P2 serves from authoritative right towards left
                    const fromPt = { x: room.p2_pos.x - 30.0, y: FLOOR_Y - 35.0 };
                    const targetX = shotType === 'clear' ? 210.0 : 465.0;
                    launchShuttle(room, fromPt, { x: targetX, y: FLOOR_Y }, shotType, 'p2', true);
                }
                break;
            }

            case 'hit': {
                const room = rooms[ws.roomCode];
                if (!room || room.status !== 'playing') return;
                if (!room.ball.active) return;

                const role = ws.playerRole;
                const shotType = data.shot_type || 'clear';
                const isSmash = Boolean(data.is_smash);
                const isPerf = Boolean(data.is_perf);

                // Authoritative contact position
                let cx = Number(data.px) || (role === 'p1' ? room.p1_pos.x + 30 : room.p2_pos.x - 30);
                if (role === 'p2') {
                    // Mirror from P2's local left to authoritative right
                    cx = 1280.0 - cx;
                }
                const cy = Number(data.py) || (FLOOR_Y - 80);

                // Target position on opponent court
                let targetX = 0;
                if (role === 'p1') {
                    targetX = shotType === 'drop' ? 760.0 : 1080.0;
                } else {
                    targetX = shotType === 'drop' ? 520.0 : 200.0;
                }

                launchShuttle(room, { x: cx, y: cy }, { x: targetX, y: FLOOR_Y }, shotType, role, false, isSmash, isPerf);

                // Broadcast shot sound & fx
                broadcastToRoom(room, {
                    t: 'shot_fx',
                    hitter: role,
                    shot_type: shotType,
                    is_smash: isSmash,
                    is_perf: isPerf,
                    cx: cx,
                    cy: cy
                });
                break;
            }
        }
    });

    ws.on('close', () => {
        if (ws.roomCode && rooms[ws.roomCode]) {
            const room = rooms[ws.roomCode];
            broadcastToRoom(room, { t: 'opponent_left' });
            delete rooms[ws.roomCode];
            console.log(`[ROOM CLOSED] Code: ${ws.roomCode}`);
        }
    });
});

function launchShuttle(room, fromPt, targetPt, shotType, hitter, isServe = false, isSmash = false, isPerf = false) {
    const dx = targetPt.x - fromPt.x;
    const dist = Math.max(Math.abs(dx), 30.0);

    let duration = 1.6;
    if (shotType === 'smash' || isSmash) {
        duration = Math.max(0.32, Math.min(0.48, dist / 2000.0));
    } else if (shotType === 'drop') {
        duration = Math.max(0.95, Math.min(1.25, dist / 600.0));
    } else if (isServe) {
        duration = shotType === 'drop' ? 1.15 : 1.70;
    } else {
        duration = Math.max(1.30, Math.min(1.75, dist / 500.0));
    }

    room.ball = {
        x: fromPt.x,
        y: fromPt.y,
        vx: dx / duration,
        vy: -400.0,
        active: true,
        serve: isServe,
        last_hitter: hitter,
        flight_time: 0,
        flight_duration: duration,
        from_x: fromPt.x,
        from_y: fromPt.y,
        target_x: targetPt.x,
        target_y: targetPt.y,
        shot_type: shotType,
        is_smash: isSmash
    };
}

function scorePoint(room, winner, reason) {
    room.status = 'point_over';
    room.ball.active = false;
    room.point_reset_timer = 2.0;

    if (winner === 'p1') {
        room.p1_pts++;
        room.server_player = 'p1';
    } else {
        room.p2_pts++;
        room.server_player = 'p2';
    }

    // Check Set Win (Target points, deuce >= 2)
    const target = room.pts;
    let setWinner = null;
    if (room.p1_pts >= target && (room.p1_pts - room.p2_pts) >= 2) {
        setWinner = 'p1';
    } else if (room.p2_pts >= target && (room.p2_pts - room.p1_pts) >= 2) {
        setWinner = 'p2';
    }

    if (setWinner) {
        if (setWinner === 'p1') room.p1_sets++;
        else room.p2_sets++;

        const setsToWin = room.sets === 1 ? 1 : 2;
        let matchWinner = null;
        if (room.p1_sets >= setsToWin) matchWinner = 'p1';
        else if (room.p2_sets >= setsToWin) matchWinner = 'p2';

        if (matchWinner) {
            room.status = 'match_over';
            broadcastToRoom(room, {
                t: 'match_over',
                winner: matchWinner,
                p1_pts: room.p1_pts,
                p2_pts: room.p2_pts,
                p1_sets: room.p1_sets,
                p2_sets: room.p2_sets
            });
            return;
        }

        // Next set
        room.current_set++;
        room.p1_pts = 0;
        room.p2_pts = 0;
    }

    // Notify clients of authoritative point
    broadcastToRoom(room, {
        t: 'point_scored',
        winner: winner,
        reason: reason,
        p1_pts: room.p1_pts,
        p2_pts: room.p2_pts,
        p1_sets: room.p1_sets,
        p2_sets: room.p2_sets,
        next_server: room.server_player
    });
}

function resetServe(room) {
    room.status = 'playing';
    room.ball.active = false;
    room.ball.serve = true;

    if (room.server_player === 'p1') {
        room.ball.x = 390.0;
        room.ball.y = FLOOR_Y - 35.0;
    } else {
        room.ball.x = 890.0;
        room.ball.y = FLOOR_Y - 35.0;
    }
    room.ball.vx = 0;
    room.ball.vy = 0;

    broadcastToRoom(room, {
        t: 'serve_ready',
        server: room.server_player
    });
}

// 60Hz Server Tick Loop
const TICK_DELTA = 1.0 / 60.0;
setInterval(() => {
    for (const code in rooms) {
        const room = rooms[code];

        // Countdown handling
        if (room.status === 'countdown') {
            room.countdown_timer -= TICK_DELTA;
            if (room.countdown_timer <= 0) {
                room.status = 'playing';
                resetServe(room);
                broadcastToRoom(room, { t: 'match_start' });
            }
            continue;
        }

        // Point Over handling
        if (room.status === 'point_over') {
            room.point_reset_timer -= TICK_DELTA;
            if (room.point_reset_timer <= 0) {
                resetServe(room);
            }
        }

        // Active Shuttlecock Physics Simulation (AUTHORITATIVE)
        if (room.status === 'playing' && room.ball.active) {
            const b = room.ball;
            b.flight_time += TICK_DELTA;
            const p = Math.min(1.0, b.flight_time / b.flight_duration);

            const prevX = b.x;
            const prevY = b.y;

            // Parametric trajectory
            b.x = b.from_x + (b.target_x - b.from_x) * p;

            if (b.is_smash) {
                b.y = b.from_y + (FLOOR_Y - b.from_y) * Math.pow(p, 1.2);
            } else if (b.shot_type === 'drop') {
                const arc = Math.sin(Math.PI * p);
                const hApex = 135.0;
                b.y = b.from_y + (FLOOR_Y - b.from_y) * p - arc * hApex;
            } else {
                // High Clear
                const arc = Math.sin(Math.PI * p);
                const hApex = 340.0;
                b.y = b.from_y + (FLOOR_Y - b.from_y) * p - arc * hApex;
            }

            b.vx = (b.x - prevX) / TICK_DELTA;
            b.vy = (b.y - prevY) / TICK_DELTA;

            // Check Net Collision
            const crossedNet = (prevX <= NET_X && b.x >= NET_X) || (prevX >= NET_X && b.x <= NET_X);
            if (crossedNet && b.y >= NET_TOP_Y) {
                // Net Fault!
                b.x = NET_X - Math.sign(b.vx) * 8.0;
                b.y = FLOOR_Y;
                const winner = b.last_hitter === 'p1' ? 'p2' : 'p1';
                scorePoint(room, winner, 'CẦU VƯỚNG LƯỚI');
                continue;
            }

            // Check Floor Landing (Only after completing full flight trajectory)
            if (p >= 1.0) {
                b.y = FLOOR_Y;

                // Line check
                let winner = 'p1';
                let reason = 'ĐIỂM TRỰC TIẾP';

                if (b.serve) {
                    if (b.last_hitter === 'p1') {
                        if (b.x < SHORT_SERVICE_RIGHT) {
                            winner = 'p2';
                            reason = 'GIAO CẦU CHƯA QUA VẠCH';
                        } else if (b.x > RIGHT_OUT_X) {
                            winner = 'p2';
                            reason = 'GIAO CẦU NGOÀI BIÊN';
                        } else {
                            winner = 'p1';
                            reason = 'GIAO CẦU ĂN ĐIỂM';
                        }
                    } else {
                        if (b.x > SHORT_SERVICE_LEFT) {
                            winner = 'p1';
                            reason = 'GIAO CẦU CHƯA QUA VẠCH';
                        } else if (b.x < LEFT_OUT_X) {
                            winner = 'p1';
                            reason = 'GIAO CẦU NGOÀI BIÊN';
                        } else {
                            winner = 'p2';
                            reason = 'GIAO CẦU ĂN ĐIỂM';
                        }
                    }
                } else {
                    if (b.last_hitter === 'p1') {
                        if (b.x > RIGHT_OUT_X || b.x < NET_X) {
                            winner = 'p2';
                            reason = 'ĐÁNH CẦU NGOÀI SÂN';
                        } else {
                            winner = 'p1';
                            reason = 'CẦU RƠI TRONG SÂN';
                        }
                    } else {
                        if (b.x < LEFT_OUT_X || b.x > NET_X) {
                            winner = 'p1';
                            reason = 'ĐÁNH CẦU NGOÀI SÂN';
                        } else {
                            winner = 'p2';
                            reason = 'CẦU RƠI TRONG SÂN';
                        }
                    }
                }

                scorePoint(room, winner, reason);
                continue;
            }
        }

        // 60Hz Broadcast Tick
        if (room.status === 'playing' || room.status === 'point_over') {
            // To P1: Natural coordinates
            sendTo(room.p1, {
                t: 'tick',
                p1: room.p1_pos,
                p2: room.p2_pos,
                ball: {
                    x: room.ball.x,
                    y: room.ball.y,
                    vx: room.ball.vx,
                    vy: room.ball.vy,
                    act: room.ball.active,
                    srv: room.ball.serve
                },
                p1_pts: room.p1_pts,
                p2_pts: room.p2_pts
            });

            // To P2: Mirrored coordinates (P2 is ALWAYS Left court on P2's screen!)
            sendTo(room.p2, {
                t: 'tick',
                p1: {
                    x: 1280.0 - room.p2_pos.x,
                    y: room.p2_pos.y,
                    vx: -room.p2_pos.vx,
                    vy: room.p2_pos.vy,
                    f: 1.0,
                    sw: room.p2_pos.sw,
                    dv: room.p2_pos.dv
                },
                p2: {
                    x: 1280.0 - room.p1_pos.x,
                    y: room.p1_pos.y,
                    vx: -room.p1_pos.vx,
                    vy: room.p1_pos.vy,
                    f: -1.0,
                    sw: room.p1_pos.sw,
                    dv: room.p1_pos.dv
                },
                ball: {
                    x: 1280.0 - room.ball.x,
                    y: room.ball.y,
                    vx: -room.ball.vx,
                    vy: room.ball.vy,
                    act: room.ball.active,
                    srv: room.ball.serve
                },
                p1_pts: room.p2_pts, // Guest's points on Left
                p2_pts: room.p1_pts  // Opponent's points on Right
            });
        }
    }
}, Math.round(TICK_DELTA * 1000));

server.listen(PORT, () => {
    console.log(`[KAISER SHUTTLE SERVER] Listening on port ${PORT}`);
});
