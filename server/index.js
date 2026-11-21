/**
 * Kaiser Shuttle - High-Performance Low-Latency PvP WebSocket Relay Server
 * 100% Deterministic Engine Relay: Preserves authentic Godot physics and game feel.
 * Runs on Render.com (Free tier), Koyeb, or Localhost.
 */

const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    // CORS headers for browser pre-warm and status queries
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }
    if (req.url === '/healthz' || req.url === '/ping') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'ok',
            activeRooms: Object.keys(rooms).length,
            clients: wss ? wss.clients.size : 0,
            uptime: process.uptime()
        }));
        return;
    }
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(`Kaiser Shuttle PvP Relay Server is ONLINE!\nActive Rooms: ${Object.keys(rooms).length}\nConnected Clients: ${wss.clients.size}\n`);
});

const wss = new WebSocket.Server({
    server,
    perMessageDeflate: false, // 10x throughput boost for small real-time game packets (disables zlib overhead)
    maxPayload: 1024 * 64
});
const rooms = {};

// Render Free tier self-keepalive (keeps server warm during active gameplay hours)
const RENDER_EXTERNAL_URL = process.env.RENDER_EXTERNAL_URL || 'https://kaiser-shuttle-server.onrender.com';
const KEEP_ALIVE_INTERVAL = 10 * 60 * 1000; // Every 10 mins
setInterval(() => {
    try {
        const https = require('https');
        const client = RENDER_EXTERNAL_URL.startsWith('https') ? https : http;
        client.get(`${RENDER_EXTERNAL_URL}/healthz`, (res) => {}).on('error', () => {});
    } catch (e) {}
}, KEEP_ALIVE_INTERVAL);

function generateRoomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    let code = '';
    for (let i = 0; i < 4; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}

function sendTo(ws, data) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(data));
    }
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

function broadcastToSpectators(room, data) {
    if (!room || !room.spectators || room.spectators.length === 0) return;
    const msg = JSON.stringify(data);
    room.spectators = room.spectators.filter(client => {
        if (client && client.readyState === WebSocket.OPEN) {
            try { client.send(msg); return true; } catch(e) { return false; }
        }
        return false;
    });
}

wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.roomCode = null;
    ws.playerRole = null; // 'p1' or 'p2'

    // Disable Nagle's algorithm & enable TCP keepalive for zero packet buffering delay (FPS-grade low latency)
    if (ws._socket) {
        if (typeof ws._socket.setNoDelay === 'function') ws._socket.setNoDelay(true);
        if (typeof ws._socket.setKeepAlive === 'function') ws._socket.setKeepAlive(true, 10000);
    }

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

                const hostName = (data.name || 'PLAYER 1').slice(0, 12).toUpperCase().trim();
                const room = {
                    code: code,
                    p1: ws,
                    p2: null,
                    spectators: [],
                    p1_char: data.char || 'nishikawa',
                    p2_char: 'wall',
                    p1_name: hostName || 'PLAYER 1',
                    p2_name: 'PLAYER 2',
                    pts: data.pts || 11,
                    sets: data.sets || 1,
                    p1_pts: 0,
                    p2_pts: 0,
                    p1_sets: 0,
                    p2_sets: 0,
                    status: 'waiting',
                    current_server: 'player'
                };

                rooms[code] = room;
                ws.roomCode = code;
                ws.playerRole = 'p1';

                sendTo(ws, {
                    t: 'room_created',
                    code: code,
                    role: 'p1',
                    pts: room.pts,
                    sets: room.sets,
                    name: room.p1_name
                });
                console.log(`[ROOM CREATED] Code: ${code} - Host: ${room.p1_name}`);
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
                    sendTo(ws, { t: 'error', msg: 'Phòng ' + code + ' đã đủ 2 người thi đấu! Bạn có thể chọn chế độ XEM (KHÁN GIẢ).' });
                    return;
                }

                const guestName = (data.name || 'PLAYER 2').slice(0, 12).toUpperCase().trim();
                room.p2 = ws;
                room.p2_char = data.char || 'wall';
                room.p2_name = guestName || 'PLAYER 2';
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
                    host_name: room.p1_name,
                    guest_name: room.p2_name,
                    pts: room.pts,
                    sets: room.sets
                });

                // Notify Host
                sendTo(room.p1, {
                    t: 'guest_joined',
                    code: code,
                    guest_char: room.p2_char,
                    guest_name: room.p2_name
                });

                console.log(`[ROOM JOINED] Code: ${code} - Guest entered: ${room.p2_name}`);
                break;
            }

            case 'join_spectator': {
                const code = (data.code || '').toUpperCase().trim();
                const room = rooms[code];

                if (!room) {
                    sendTo(ws, { t: 'error', msg: 'Không tìm thấy phòng ' + code });
                    return;
                }

                if (!room.spectators) room.spectators = [];
                room.spectators.push(ws);
                ws.roomCode = code;
                ws.playerRole = 'spectator';

                sendTo(ws, {
                    t: 'spectator_joined',
                    code: code,
                    role: 'spectator',
                    p1_char: room.p1_char,
                    p2_char: room.p2_char,
                    pts: room.pts,
                    sets: room.sets,
                    p1_pts: room.p1_pts,
                    p2_pts: room.p2_pts,
                    p1_sets: room.p1_sets,
                    p2_sets: room.p2_sets,
                    status: room.status,
                    current_server: room.current_server
                });

                console.log(`[SPECTATOR JOINED] Code: ${code} - Watching (Total spectators: ${room.spectators.length})`);
                break;
            }

            case 'start_match': {
                if (ws.playerRole !== 'p1') return;
                const room = rooms[ws.roomCode];
                if (!room || !room.p2) return;

                room.pts = data.pts || room.pts;
                room.sets = data.sets || room.sets;
                room.status = 'playing';

                // Authoritative first server coin toss: p1 or p2
                const firstServer = (data.first_server === 'p1' || data.first_server === 'p2')
                    ? data.first_server
                    : (Math.random() < 0.5 ? 'p1' : 'p2');
                room.current_server = firstServer;

                const countdownMsg = {
                    t: 'countdown_start',
                    seconds: 3,
                    pts: room.pts,
                    sets: room.sets,
                    p1_char: room.p1_char,
                    p2_char: room.p2_char,
                    p1_name: room.p1_name || 'PLAYER 1',
                    p2_name: room.p2_name || 'PLAYER 2',
                    first_server: firstServer
                };
                broadcastToRoom(room, countdownMsg);
                broadcastToSpectators(room, countdownMsg);
                console.log(`[MATCH START] Room: ${ws.roomCode} - First Serve: ${firstServer}`);
                break;
            }

            // Real-time Player Movement & Kinematics Sync (60Hz)
            case 'sync':
            case 'player_input': {
                const room = rooms[ws.roomCode];
                if (!room) return;

                const isP1 = (ws.playerRole === 'p1');
                const target = isP1 ? room.p2 : room.p1;
                if (target && target.readyState === WebSocket.OPEN) {
                    // Send mirrored position, kinematics, and athletic stats to opponent
                    target.send(JSON.stringify({
                        t: 'opp_sync',
                        x: 1280.0 - Number(data.x || 0),
                        y: Number(data.y || 0),
                        vx: -Number(data.vx || 0),
                        vy: Number(data.vy || 0),
                        f: -Number(data.f || 1.0),
                        sw: Boolean(data.sw),
                        dv: Boolean(data.dv),
                        wp: Number(data.wp || 0),
                        bal: Number(data.bal || 100.0),
                        stm: Number(data.stm != null ? data.stm : 100.0),
                        cap: Number(data.cap != null ? data.cap : 100.0),
                        acc: Number(data.acc != null ? data.acc : 100.0)
                    }));
                }

                // Relay to spectators: P1 on left (normal), P2 on right (mirrored)
                if (room.spectators && room.spectators.length > 0) {
                    broadcastToSpectators(room, {
                        t: 'spec_sync',
                        role: isP1 ? 'p1' : 'p2',
                        x: isP1 ? Number(data.x || 0) : (1280.0 - Number(data.x || 0)),
                        y: Number(data.y || 0),
                        vx: isP1 ? Number(data.vx || 0) : -Number(data.vx || 0),
                        vy: Number(data.vy || 0),
                        f: isP1 ? Number(data.f || 1.0) : -Number(data.f || 1.0),
                        sw: Boolean(data.sw),
                        dv: Boolean(data.dv),
                        wp: Number(data.wp || 0),
                        bal: Number(data.bal || 100.0),
                        stm: Number(data.stm != null ? data.stm : 100.0),
                        cap: Number(data.cap != null ? data.cap : 100.0),
                        acc: Number(data.acc != null ? data.acc : 100.0)
                    });
                }
                break;
            }

            // Real-time Authentic Shot Hit Event
            case 'shot':
            case 'hit': {
                const room = rooms[ws.roomCode];
                if (!room) return;

                const isP1 = (ws.playerRole === 'p1');
                const target = isP1 ? room.p2 : room.p1;
                if (target && target.readyState === WebSocket.OPEN) {
                    // Mirror launch coordinates for opponent:
                    target.send(JSON.stringify({
                        t: 'opp_shot',
                        from_x: 1280.0 - Number(data.from_x != null ? data.from_x : (data.px || 0)),
                        from_y: Number(data.from_y != null ? data.from_y : (data.py || 0)),
                        target_x: 1280.0 - Number(data.target_x != null ? data.target_x : 390.0),
                        target_y: Number(data.target_y != null ? data.target_y : 550.0),
                        shot_type: String(data.shot_type || 'clear'),
                        err: -Number(data.err || 0),
                        is_perf: Boolean(data.is_perf),
                        is_jump: Boolean(data.is_jump),
                        t_mult: Number(data.t_mult || 1.0),
                        t_lvl: Number(data.t_lvl || 0),
                        quality: Number(data.quality || 0.8),
                        stm: Number(data.stm != null ? data.stm : 100.0),
                        cap: Number(data.cap != null ? data.cap : 100.0),
                        acc: Number(data.acc != null ? data.acc : 100.0)
                    }));
                }

                // Relay to spectators
                if (room.spectators && room.spectators.length > 0) {
                    broadcastToSpectators(room, {
                        t: 'spec_shot',
                        role: isP1 ? 'p1' : 'p2',
                        from_x: isP1 ? Number(data.from_x != null ? data.from_x : (data.px || 0)) : (1280.0 - Number(data.from_x != null ? data.from_x : (data.px || 0))),
                        from_y: Number(data.from_y != null ? data.from_y : (data.py || 0)),
                        target_x: isP1 ? Number(data.target_x != null ? data.target_x : 890.0) : (1280.0 - Number(data.target_x != null ? data.target_x : 390.0)),
                        target_y: Number(data.target_y != null ? data.target_y : 550.0),
                        shot_type: String(data.shot_type || 'clear'),
                        err: isP1 ? Number(data.err || 0) : -Number(data.err || 0),
                        is_perf: Boolean(data.is_perf),
                        is_jump: Boolean(data.is_jump),
                        t_mult: Number(data.t_mult || 1.0),
                        t_lvl: Number(data.t_lvl || 0),
                        quality: Number(data.quality || 0.8),
                        stm: Number(data.stm != null ? data.stm : 100.0),
                        cap: Number(data.cap != null ? data.cap : 100.0),
                        acc: Number(data.acc != null ? data.acc : 100.0)
                    });
                }
                break;
            }

            // Real-time Serve Event
            case 'serve': {
                const room = rooms[ws.roomCode];
                if (!room) return;

                const isP1 = (ws.playerRole === 'p1');
                const target = isP1 ? room.p2 : room.p1;
                if (target && target.readyState === WebSocket.OPEN) {
                    target.send(JSON.stringify({
                        t: 'opp_serve',
                        shot_type: String(data.shot_type || 'clear')
                    }));
                }

                if (room.spectators && room.spectators.length > 0) {
                    broadcastToSpectators(room, {
                        t: 'spec_serve',
                        role: isP1 ? 'p1' : 'p2',
                        shot_type: String(data.shot_type || 'clear')
                    });
                }
                break;
            }

            // Authoritative Score Event (Host is referee)
            case 'score': {
                if (ws.playerRole !== 'p1') return;
                const room = rooms[ws.roomCode];
                if (!room || !room.p2) return;

                room.p1_pts = Number(data.p1_pts || 0);
                room.p2_pts = Number(data.p2_pts || 0);
                room.p1_sets = Number(data.p1_sets || 0);
                room.p2_sets = Number(data.p2_sets || 0);
                room.current_server = data.next_server === 'player' ? 'p1' : 'p2';

                // For Guest (p2): invert winner and scores so Guest is always player (Left)
                const winnerRole = data.winner; // 'player' (Host) or 'ai' (Guest)
                const guestWinner = winnerRole === 'player' ? 'ai' : 'player';

                sendTo(room.p2, {
                    t: 'score_update',
                    winner: guestWinner,
                    reason: String(data.reason || ''),
                    p1_pts: Number(data.p2_pts || 0), // Guest's pts
                    p2_pts: Number(data.p1_pts || 0), // Host's pts
                    p1_sets: Number(data.p2_sets || 0),
                    p2_sets: Number(data.p1_sets || 0),
                    next_server: data.next_server === 'player' ? 'ai' : 'player',
                    cur_set: Number(data.cur_set != null ? data.cur_set : 0),
                    s_p1: Array.isArray(data.s_p2) ? data.s_p2 : [], // For Guest: Guest's set history
                    s_p2: Array.isArray(data.s_p1) ? data.s_p1 : [], // For Guest: Host's set history
                    s_win: Array.isArray(data.s_win) ? data.s_win.map(w => w === 0 ? 1 : (w === 1 ? 0 : w)) : [-1, -1, -1],
                    max_sets: Number(data.max_sets || room.sets || 1)
                });

                // For Spectators: normal Host (P1) vs Guest (P2)
                if (room.spectators && room.spectators.length > 0) {
                    broadcastToSpectators(room, {
                        t: 'spec_score',
                        winner: winnerRole,
                        reason: String(data.reason || ''),
                        p1_pts: room.p1_pts,
                        p2_pts: room.p2_pts,
                        p1_sets: room.p1_sets,
                        p2_sets: room.p2_sets,
                        next_server: data.next_server === 'player' ? 'p1' : 'p2',
                        cur_set: Number(data.cur_set != null ? data.cur_set : 0),
                        s_p1: Array.isArray(data.s_p1) ? data.s_p1 : [],
                        s_p2: Array.isArray(data.s_p2) ? data.s_p2 : [],
                        s_win: Array.isArray(data.s_win) ? data.s_win : [-1, -1, -1],
                        max_sets: Number(data.max_sets || room.sets || 1)
                    });
                }
                break;
            }

            // Match Over Event
            case 'match_over': {
                if (ws.playerRole !== 'p1') return;
                const room = rooms[ws.roomCode];
                if (!room || !room.p2) return;

                room.status = 'match_over';
                const winner = data.winner; // 'player' or 'ai'
                sendTo(room.p2, {
                    t: 'match_over_update',
                    winner: winner === 'player' ? 'ai' : 'player'
                });

                if (room.spectators && room.spectators.length > 0) {
                    broadcastToSpectators(room, {
                        t: 'spec_match_over',
                        winner: winner
                    });
                }
                break;
            }

            // Direct Peer Relays: Character Init & Special Skill Recoil Sync
            case 'init':
            case 'init_ack':
            case 'skill_recoil': {
                const room = rooms[ws.roomCode];
                if (!room) return;
                const isP1 = (ws.playerRole === 'p1');
                const target = isP1 ? room.p2 : room.p1;
                if (target && target.readyState === WebSocket.OPEN) {
                    target.send(JSON.stringify(data));
                }
                break;
            }
        }
    });

    ws.on('close', () => {
        if (ws.roomCode && rooms[ws.roomCode]) {
            const room = rooms[ws.roomCode];
            if (ws.playerRole === 'spectator') {
                if (room.spectators) {
                    room.spectators = room.spectators.filter(c => c !== ws);
                }
                console.log(`[SPECTATOR LEFT] Code: ${ws.roomCode} - Spectator left (Remaining: ${room.spectators ? room.spectators.length : 0})`);
            } else {
                // Host (P1) or Guest (P2) left
                broadcastToRoom(room, { t: 'opponent_left' });
                broadcastToSpectators(room, { t: 'room_closed', msg: 'Một trong hai đấu thủ đã rời trận đấu.' });
                delete rooms[ws.roomCode];
                console.log(`[ROOM CLOSED] Code: ${ws.roomCode}`);
            }
        }
    });
});

// Periodic Heartbeat to keep WebSockets alive
setInterval(() => {
    wss.clients.forEach((ws) => {
        if (!ws.isAlive) return ws.terminate();
        ws.isAlive = false;
        ws.ping();
    });
}, 30000);

server.listen(PORT, () => {
    console.log(`[KAISER SHUTTLE RELAY SERVER] Listening on port ${PORT}`);
});
