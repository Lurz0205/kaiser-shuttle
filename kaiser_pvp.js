/**
 * Kaiser Shuttle - WebRTC P2P Low-Latency Multiplayer Bridge
 * Uses PeerJS (0.peerjs.com signaling + Google STUN)
 * Operates over WebRTC DataChannel (reliable: false / UDP unordered mode for minimum jitter & latency)
 */
(function() {
    'use strict';

    window.KaiserNet = {
        peer: null,
        conn: null,
        isHost: false,
        roomCode: '',
        status: 'idle', // 'idle', 'hosting', 'connecting', 'connected', 'disconnected', 'error'
        lastError: '',
        ping: 0,
        lastPingTs: 0,
        packetQueue: [],
        pingInterval: null,

        reset: function() {
            if (this.pingInterval) {
                clearInterval(this.pingInterval);
                this.pingInterval = null;
            }
            if (this.conn) {
                try { this.conn.close(); } catch(e) {}
                this.conn = null;
            }
            if (this.peer) {
                try { this.peer.destroy(); } catch(e) {}
                this.peer = null;
            }
            this.isHost = false;
            this.roomCode = '';
            this.status = 'idle';
            this.lastError = '';
            this.ping = 0;
            this.packetQueue = [];
        },

        initHost: function(code) {
            this.reset();
            this.isHost = true;
            this.roomCode = (code || '').toUpperCase().trim();
            var peerId = 'kaiser-' + this.roomCode;
            this.status = 'hosting';

            var self = this;
            try {
                if (typeof Peer === 'undefined') {
                    self.status = 'error';
                    self.lastError = 'PeerJS library not loaded';
                    return;
                }

                self.peer = new Peer(peerId, {
                    debug: 1,
                    config: {
                        iceServers: [
                            { urls: 'stun:stun.l.google.com:19302' },
                            { urls: 'stun:stun1.l.google.com:19302' },
                            { urls: 'stun:stun2.l.google.com:19302' }
                        ]
                    }
                });

                self.peer.on('open', function(id) {
                    self.status = 'hosting';
                });

                self.peer.on('connection', function(incomingConn) {
                    if (self.conn) {
                        incomingConn.close();
                        return;
                    }
                    self.conn = incomingConn;
                    self._setupConnection(incomingConn);
                });

                self.peer.on('error', function(err) {
                    console.error('[KaiserNet Host Error]', err);
                    self.status = 'error';
                    self.lastError = err.type || err.message || 'Host error';
                });

                self.peer.on('disconnected', function() {
                    if (self.status === 'connected') {
                        self.status = 'disconnected';
                    }
                });
            } catch (e) {
                self.status = 'error';
                self.lastError = e.message;
            }
        },

        initGuest: function(code) {
            this.reset();
            this.isHost = false;
            this.roomCode = (code || '').toUpperCase().trim();
            var targetHostId = 'kaiser-' + this.roomCode;
            this.status = 'connecting';

            var self = this;
            try {
                if (typeof Peer === 'undefined') {
                    self.status = 'error';
                    self.lastError = 'PeerJS library not loaded';
                    return;
                }

                self.peer = new Peer(null, {
                    debug: 1,
                    config: {
                        iceServers: [
                            { urls: 'stun:stun.l.google.com:19302' },
                            { urls: 'stun:stun1.l.google.com:19302' },
                            { urls: 'stun:stun2.l.google.com:19302' }
                        ]
                    }
                });

                self.peer.on('open', function(id) {
                    // Connect with reliable: false for raw low-latency UDP behavior
                    var conn = self.peer.connect(targetHostId, {
                        reliable: false,
                        serialization: 'json'
                    });
                    self.conn = conn;
                    self._setupConnection(conn);
                });

                self.peer.on('error', function(err) {
                    console.error('[KaiserNet Guest Error]', err);
                    self.status = 'error';
                    self.lastError = err.type || err.message || 'Connection failed';
                });

                self.peer.on('disconnected', function() {
                    if (self.status === 'connected') {
                        self.status = 'disconnected';
                    }
                });
            } catch (e) {
                self.status = 'error';
                self.lastError = e.message;
            }
        },

        _setupConnection: function(conn) {
            var self = this;

            conn.on('open', function() {
                self.status = 'connected';

                // Setup periodic ping every 1000ms
                if (self.pingInterval) clearInterval(self.pingInterval);
                self.pingInterval = setInterval(function() {
                    if (self.conn && self.conn.open) {
                        self.lastPingTs = performance.now();
                        try {
                            self.conn.send({ _type: 'ping', ts: self.lastPingTs });
                        } catch(e) {}
                    }
                }, 1000);
            });

            conn.on('data', function(data) {
                if (!data) return;

                // Handle internal ping/pong
                if (data._type === 'ping') {
                    try {
                        conn.send({ _type: 'pong', ts: data.ts });
                    } catch(e) {}
                    return;
                } else if (data._type === 'pong') {
                    var now = performance.now();
                    self.ping = Math.max(1, Math.round(now - data.ts));
                    return;
                }

                // Push game packets to queue (bounded to prevent backlog lag)
                if (self.packetQueue.length >= 15) {
                    self.packetQueue.shift();
                }
                self.packetQueue.push(data);
            });

            conn.on('close', function() {
                self.status = 'disconnected';
            });

            conn.on('error', function(err) {
                console.error('[KaiserNet Conn Error]', err);
                self.status = 'error';
                self.lastError = err.message || 'DataChannel error';
            });
        },

        sendPacket: function(packet) {
            if (this.conn && this.conn.open) {
                try {
                    this.conn.send(packet);
                    return true;
                } catch(e) {
                    return false;
                }
            }
            return false;
        },

        getPackets: function() {
            if (this.packetQueue.length === 0) return '[]';
            var json = JSON.stringify(this.packetQueue);
            this.packetQueue = [];
            return json;
        },

        getStatus: function() {
            return JSON.stringify({
                status: this.status,
                isHost: this.isHost,
                roomCode: this.roomCode,
                ping: this.ping,
                lastError: this.lastError
            });
        }
    };
})();
