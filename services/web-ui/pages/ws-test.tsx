import { useEffect, useState, useRef } from 'react';
import { authService } from '@/lib/api/services/auth.service';
import {
  ProjectNotificationMessage,
  JobNotificationMessage,
  ProjectStatus,
  JobStatus,
  Platform,
  ProjectPhaseMessage,
  isPhaseBasedMessage,
} from '@/lib/types/websocket';

// Legacy message format for backward compatibility testing
interface LegacyWSMessage<T = any> {
  type: string;
  payload: T;
  timestamp: string;
}

const WS_BASE_URL = process.env.NEXT_PUBLIC_WS_URL || 'wss://smap-api.tantai.dev:8081/ws';

export default function WebSocketTest() {
  const [connected, setConnected] = useState(false);
  const [messages, setMessages] = useState<(ProjectNotificationMessage | JobNotificationMessage | ProjectPhaseMessage | LegacyWSMessage)[]>([]);
  const [connectionStatus, setConnectionStatus] = useState('Disconnected');
  const wsRef = useRef<any>(null);

  // Connection type
  const [connectionType, setConnectionType] = useState<'project' | 'job'>('project');
  const [projectId, setProjectId] = useState('');
  const [jobId, setJobId] = useState('');

  // Login form states
  const [showLoginForm, setShowLoginForm] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setLoginError('');

    try {
      const payload = {
        email,
        password,
        device_name: 'WebSocket Test Page',
        ip_address: '0.0.0.0',
        user_agent: navigator.userAgent,
        remember: true,
      };

      console.log('🔐 Đang đăng nhập...');
      const response = await authService.login(payload);
      console.log('📦 Login response:', response);

      // Check if user needs OTP verification (error_code 20009)
      if (response.error_code === 20009) {
        setLoginError('Tài khoản cần xác thực OTP. Vui lòng xác thực tài khoản trước.');
        setIsLoggingIn(false);
        return;
      }

      if (response.data || response.token) {
        console.log('Đăng nhập thành công - sử dụng HttpOnly Cookie');
        setIsLoggedIn(true);
        setShowLoginForm(false);
        setLoginError('');

        // Auto-connect after login (uses HttpOnly Cookie)
        setTimeout(() => {
          connect();
        }, 300);
      } else {
        setLoginError('Đăng nhập thất bại. Vui lòng kiểm tra thông tin.');
      }

    } catch (err: any) {
      console.error('Login error:', err);
      setLoginError(err?.message || 'Đăng nhập thất bại. Vui lòng thử lại.');
    } finally {
      setIsLoggingIn(false);
    }
  };

  const connect = () => {
    if (!isLoggedIn) {
      alert('Vui lòng đăng nhập trước khi kết nối!');
      return;
    }

    if (connectionType === 'project' && !projectId) {
      alert('Vui lòng nhập Project ID!');
      return;
    }

    if (connectionType === 'job' && !jobId) {
      alert('Vui lòng nhập Job ID!');
      return;
    }

    try {
      setConnectionStatus('Connecting...');

      // Build WebSocket URL with query params (new format)
      const baseUrl = WS_BASE_URL;
      let wsUrl: string;

      if (connectionType === 'project') {
        wsUrl = `${baseUrl}?project_id=${projectId}`;
        console.log('🔗 Đang kết nối Project WebSocket:', projectId);
      } else {
        wsUrl = `${baseUrl}?job_id=${jobId}`;
        console.log('🔗 Đang kết nối Job WebSocket:', jobId);
      }

      // Create native WebSocket connection (uses HttpOnly Cookie for auth)
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws as any; // Type assertion to avoid TypeScript issues

      ws.onopen = () => {
        console.log('Đã kết nối WebSocket thành công!');
        setConnected(true);
        setConnectionStatus('Connected');
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log('📨 Nhận tin nhắn:', data);

          // Handle different message formats
          let message: ProjectNotificationMessage | JobNotificationMessage | ProjectPhaseMessage | LegacyWSMessage;

          // Check for phase-based format first (new format with type wrapper)
          if (isPhaseBasedMessage(data)) {
            message = data as ProjectPhaseMessage;
            console.log('🔄 [Phase-Based] Message detected:', data.type);
          } else if (data.type && data.payload && data.timestamp) {
            // Legacy format with type/payload/timestamp
            message = data as LegacyWSMessage;
            console.log('📦 [Legacy] Message detected:', data.type);
          } else {
            // New flat format
            message = data as ProjectNotificationMessage | JobNotificationMessage;
            console.log('📋 [Flat] Message detected');
          }

          setMessages(prev => [message, ...prev].slice(0, 50));
          handleMessage(message);
        } catch (err) {
          console.error('Lỗi parse tin nhắn:', err);
        }
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        setConnectionStatus('Error');
      };

      ws.onclose = (event) => {
        console.log('🔌 Đã ngắt kết nối WebSocket');
        console.log('   - Code:', event.code);
        console.log('   - Reason:', event.reason || 'Không có lý do');
        console.log('   - Clean:', event.wasClean);

        setConnected(false);
        setConnectionStatus(`Disconnected (${event.code})`);

        if (event.code === 1006) {
          setConnectionStatus('Error: Authentication failed hoặc CORS issue (1006)');
          console.error('⚠️ Lỗi 1006 - Có thể do:');
          console.error('   1. HttpOnly Cookie không hợp lệ hoặc hết hạn');
          console.error('   2. CORS: Origin không được whitelist');
          console.error('   3. Server từ chối kết nối');
        } else if (event.code === 1008) {
          setConnectionStatus('Error: Policy violation (1008)');
        } else if (event.code === 4001) {
          setConnectionStatus('Error: Unauthorized (4001)');
        }
      };

    } catch (err) {
      console.error('Lỗi kết nối:', err);
      setConnectionStatus('Error');
    }
  };

  const disconnect = () => {
    if (wsRef.current) {
      (wsRef.current as any).close();
      wsRef.current = null;
    }
  };

  const handleMessage = (msg: ProjectNotificationMessage | JobNotificationMessage | ProjectPhaseMessage | LegacyWSMessage) => {
    // Handle phase-based format (new format with type wrapper for phases)
    if (isPhaseBasedMessage(msg)) {
      const phaseMsg = msg as ProjectPhaseMessage;
      console.log(`🔄 [Phase-Based] ${phaseMsg.type}`);
      console.log(`   Project ID: ${phaseMsg.payload.project_id}`);
      console.log(`   Status: ${phaseMsg.payload.status}`);
      console.log(`   Overall: ${phaseMsg.payload.overall_progress_percent}%`);

      if (phaseMsg.payload.crawl) {
        const c = phaseMsg.payload.crawl;
        console.log(`   🔍 Crawl: ${c.done}/${c.total} (${c.progress_percent}%) - ${c.errors} errors`);
      }
      if (phaseMsg.payload.analyze) {
        const a = phaseMsg.payload.analyze;
        console.log(`   📊 Analyze: ${a.done}/${a.total} (${a.progress_percent}%) - ${a.errors} errors`);
      }
      return;
    }

    // Handle legacy format
    if ('type' in msg && 'payload' in msg && 'timestamp' in msg) {
      const legacyMsg = msg as LegacyWSMessage;
      switch (legacyMsg.type) {
        case 'project_progress':
          console.log(`📊 [Legacy] Tiến độ dự án:`, legacyMsg.payload);
          break;
        case 'project_completed':
          console.log(`✅ [Legacy] Dự án hoàn thành:`, legacyMsg.payload);
          break;
        case 'dryrun_result':
          console.log(`🧪 [Legacy] Kết quả Dry Run:`, legacyMsg.payload);
          break;
        default:
          console.warn('⚠️ [Legacy] Loại tin nhắn không xác định:', legacyMsg.type);
      }
      return;
    }

    // Handle new flat format
    const newMsg = msg as ProjectNotificationMessage | JobNotificationMessage;

    if ('platform' in newMsg) {
      // Job message (has platform field)
      const jobMsg = newMsg as JobNotificationMessage;
      console.log(`💼 Job (${jobMsg.platform}) - Status: ${jobMsg.status}`);
      if (jobMsg.progress) {
        console.log(`   Progress: ${jobMsg.progress.current}/${jobMsg.progress.total} (${jobMsg.progress.percentage}%)`);
      }
      if (jobMsg.batch) {
        console.log(`   Batch: ${jobMsg.batch.keyword} - ${jobMsg.batch.content_list.length} items`);
      }
    } else {
      // Project message (no platform field)
      const projectMsg = newMsg as ProjectNotificationMessage;
      console.log(`📋 Project - Status: ${projectMsg.status}`);
      if (projectMsg.progress) {
        console.log(`   Progress: ${projectMsg.progress.current}/${projectMsg.progress.total} (${projectMsg.progress.percentage}%)`);
        if (projectMsg.progress.eta) {
          console.log(`   ETA: ${projectMsg.progress.eta} minutes`);
        }
      }
    }
  };

  useEffect(() => {
    return () => {
      disconnect();
    };
  }, []);

  const getStatusColor = () => {
    if (connected) return 'text-green-500';
    if (connectionStatus.includes('Error')) return 'text-red-500';
    if (connectionStatus.includes('Connecting')) return 'text-yellow-500';
    return 'text-gray-500';
  };

  const formatMessage = (msg: ProjectNotificationMessage | JobNotificationMessage | ProjectPhaseMessage | LegacyWSMessage) => {
    // Handle phase-based format
    if (isPhaseBasedMessage(msg)) {
      const phaseMsg = msg as ProjectPhaseMessage;
      return {
        type: `[Phase] ${phaseMsg.type} (${phaseMsg.payload.status})`,
        content: JSON.stringify(phaseMsg, null, 2),
        timestamp: new Date().toISOString()
      };
    }

    // Handle legacy format
    if ('type' in msg && 'payload' in msg && 'timestamp' in msg) {
      return {
        type: `[Legacy] ${msg.type}`,
        content: JSON.stringify(msg.payload, null, 2),
        timestamp: msg.timestamp
      };
    }

    // New flat format
    const newMsg = msg as ProjectNotificationMessage | JobNotificationMessage;
    if ('platform' in newMsg) {
      return {
        type: `Job (${newMsg.status})`,
        content: JSON.stringify(newMsg, null, 2),
        timestamp: new Date().toISOString()
      };
    } else {
      return {
        type: `Project (${newMsg.status})`,
        content: JSON.stringify(newMsg, null, 2),
        timestamp: new Date().toISOString()
      };
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">WebSocket Test Page</h1>

        {/* Login Panel */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Xác thực</h2>

          {!isLoggedIn ? (
            <>
              {!showLoginForm ? (
                <div className="flex gap-4">
                  <button
                    onClick={() => setShowLoginForm(true)}
                    className="px-6 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600"
                  >
                    Đăng nhập để lấy HttpOnly Cookie
                  </button>
                  <span className="text-gray-500 self-center">Cần đăng nhập để sử dụng WebSocket</span>
                </div>
              ) : (
                <form onSubmit={handleLogin} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">Email</label>
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="email@example.com"
                      className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                      required
                      disabled={isLoggingIn}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">Password</label>
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                      required
                      disabled={isLoggingIn}
                    />
                  </div>

                  {loginError && (
                    <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                      {loginError}
                    </div>
                  )}

                  <div className="flex gap-3">
                    <button
                      type="submit"
                      disabled={isLoggingIn}
                      className="px-6 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                      {isLoggingIn ? 'Đang đăng nhập...' : 'Đăng nhập'}
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowLoginForm(false);
                        setLoginError('');
                      }}
                      className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                    >
                      Hủy
                    </button>
                  </div>
                </form>
              )}
            </>
          ) : (
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 bg-green-500 rounded-full"></span>
                <span className="text-sm font-medium text-green-700">Đã đăng nhập</span>
              </div>
              <button
                onClick={() => {
                  setIsLoggedIn(false);
                  setEmail('');
                  setPassword('');
                  disconnect();
                }}
                className="px-4 py-1 text-sm bg-gray-200 rounded hover:bg-gray-300"
              >
                Đăng xuất
              </button>
            </div>
          )}
        </div>

        {/* Connection Panel */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Kết nối WebSocket</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium mb-2">Loại kết nối</label>
              <select
                value={connectionType}
                onChange={(e) => setConnectionType(e.target.value as 'project' | 'job')}
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={connected}
              >
                <option value="project">Project WebSocket</option>
                <option value="job">Job WebSocket</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">
                {connectionType === 'project' ? 'Project ID' : 'Job ID'}
              </label>
              <input
                type="text"
                value={connectionType === 'project' ? projectId : jobId}
                onChange={(e) => {
                  if (connectionType === 'project') {
                    setProjectId(e.target.value);
                  } else {
                    setJobId(e.target.value);
                  }
                }}
                placeholder={connectionType === 'project' ? "Nhập Project ID..." : "Nhập Job ID..."}
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={connected}
              />
            </div>
          </div>

          <div className="mb-4">
            <p className="text-xs text-gray-500">
              <strong>Endpoint:</strong> {WS_BASE_URL}
            </p>
            <p className="text-xs text-gray-500">
              <strong>Authentication:</strong> HttpOnly Cookie (tự động sau khi đăng nhập)
            </p>
            <p className="text-xs text-gray-500">
              <strong>Connection URL:</strong> {connectionType === 'project'
                ? `${WS_BASE_URL}?project_id=${projectId || '{project_id}'}`
                : `${WS_BASE_URL}?job_id=${jobId || '{job_id}'}`
              }
            </p>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={connect}
              disabled={connected || !isLoggedIn || (connectionType === 'project' ? !projectId : !jobId)}
              className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Kết nối
            </button>

            <button
              onClick={disconnect}
              disabled={!connected}
              className="px-6 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Ngắt kết nối
            </button>

            <div className="flex items-center gap-2">
              <span className="text-sm font-medium">Trạng thái:</span>
              <span className={`text-sm font-semibold ${getStatusColor()}`}>
                {connectionStatus}
              </span>
            </div>
          </div>
        </div>

        {/* Messages Panel */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold">
              Tin nhắn ({messages.length})
            </h2>
            <button
              onClick={() => setMessages([])}
              className="px-4 py-1 text-sm bg-gray-200 rounded hover:bg-gray-300"
            >
              Xóa tất cả
            </button>
          </div>

          <div className="space-y-4 max-h-[600px] overflow-y-auto">
            {messages.length === 0 ? (
              <div className="text-center text-gray-500 py-8">
                Chưa có tin nhắn nào. Kết nối để nhận tin nhắn từ server.
              </div>
            ) : (
              messages.map((msg, index) => {
                const formatted = formatMessage(msg);
                return (
                  <div
                    key={index}
                    className="border rounded-lg p-4 bg-gray-50 hover:bg-gray-100"
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-semibold rounded">
                          {formatted.type}
                        </span>
                        <span className="text-xs text-gray-500">
                          {new Date(formatted.timestamp).toLocaleString('vi-VN')}
                        </span>
                      </div>
                    </div>

                    <div className="bg-white p-3 rounded border">
                      <pre className="text-xs overflow-x-auto">
                        {formatted.content}
                      </pre>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Info Panel */}
        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h3 className="font-semibold text-blue-900 mb-2">📝 Hướng dẫn sử dụng:</h3>
          <ul className="text-sm text-blue-800 space-y-1">
            <li>1. <strong>Đăng nhập</strong> để thiết lập HttpOnly Cookie authentication</li>
            <li>2. Chọn loại kết nối: <strong>Project</strong> (theo dõi tiến độ dự án) hoặc <strong>Job</strong> (theo dõi job xử lý)</li>
            <li>3. Nhập <strong>Project ID</strong> hoặc <strong>Job ID</strong> tương ứng</li>
            <li>4. Click <strong>"Kết nối"</strong> để thiết lập WebSocket connection</li>
            <li>5. Tin nhắn real-time sẽ hiển thị tự động bên dưới</li>
          </ul>

          <div className="mt-4 pt-4 border-t border-blue-200">
            <h4 className="font-semibold text-blue-900 mb-2">🔧 Thông tin kỹ thuật:</h4>
            <ul className="text-xs text-blue-700 space-y-1">
              <li><strong>Port:</strong> 8081 (thay đổi từ 8080)</li>
              <li><strong>Authentication:</strong> HttpOnly Cookie (không còn JWT token trong URL)</li>
              <li><strong>URL Pattern:</strong> Query params thay vì path params</li>
              <li><strong>Message Format:</strong> Flat structure (không còn type wrapper)</li>
              <li><strong>Project Status:</strong> PROCESSING, COMPLETED, FAILED, PAUSED</li>
              <li><strong>Job Status:</strong> PROCESSING, COMPLETED, FAILED, PAUSED</li>
              <li><strong>Backward Compatibility:</strong> Hỗ trợ cả format cũ và mới</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}