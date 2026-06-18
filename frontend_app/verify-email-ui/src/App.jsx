import { useEffect, useState } from "react";

function App() {
  const [status, setStatus] = useState("loading");
  const [message, setMessage] = useState("Verifying your email...");

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const token = params.get("token");

    if (!token) {
      setStatus('idle');
      setMessage('CuanBuddy Web Services are running successfully. This portal is used for secure email verifications.');
      return;
    }

    const verifyEmail = async () => {
      try {
        const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';
        const response = await fetch(`${backendUrl}/api/auth/verify?token=${token}`);
        const data = await response.json();

        if (response.ok) {
          setStatus("success");
          setMessage(data.message || "Account successfully verified!");
        } else {
          setStatus("error");
          setMessage(data.message || "Verification failed.");
        }
      } catch (error) {
        setStatus("error");
        setMessage("Network error. Unable to reach the server.");
      }
    };

    // Add artificial delay for aesthetic loading effect
    setTimeout(() => {
      verifyEmail();
    }, 1500);
  }, []);

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[radial-gradient(ellipse_at_top,var(--tw-gradient-stops))] from-slate-900 via-[#0f172a] to-black p-4 font-sans text-white relative overflow-hidden">
      {/* Dynamic Background Blurs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-[120px] pointer-events-none" />

      {/* Main Glassmorphism Card */}
      <div className="relative w-full max-w-md backdrop-blur-xl bg-white/5 border border-white/10 rounded-3xl p-8 shadow-[0_0_40px_rgba(0,0,0,0.5)] flex flex-col items-center text-center transition-all duration-500 ease-out transform translate-y-0">
        {/* Logo/Icon Container */}
        <div className="mb-6 relative">
          {status === "loading" && (
            <div className="w-20 h-20 rounded-full bg-blue-500/20 flex items-center justify-center border border-blue-500/30 animate-pulse">
              <svg
                className="w-10 h-10 text-blue-400 animate-spin"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                ></circle>
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
            </div>
          )}

          {status === 'success' && (
            <div className="w-20 h-20 rounded-full bg-emerald-500/20 flex items-center justify-center border border-emerald-500/30 shadow-[0_0_30px_rgba(16,185,129,0.3)] animate-[bounce_1s_ease-in-out]">
              <svg className="w-10 h-10 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" />
              </svg>
              {/* Sparkle effects */}
              <div className="absolute -top-2 -right-2 w-4 h-4 bg-emerald-400 rounded-full animate-ping" />
              <div className="absolute -bottom-1 -left-2 w-3 h-3 bg-emerald-300 rounded-full animate-ping delay-150" />
            </div>
          )}

          {status === 'idle' && (
            <div className="w-20 h-20 rounded-full bg-blue-500/20 flex items-center justify-center border border-blue-500/30 shadow-[0_0_30px_rgba(59,130,246,0.3)] animate-[pulse_3s_ease-in-out_infinite]">
              <svg className="w-10 h-10 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
          )}

          {status === "error" && (
            <div className="w-20 h-20 rounded-full bg-rose-500/20 flex items-center justify-center border border-rose-500/30 shadow-[0_0_30px_rgba(244,63,94,0.3)] animate-[shake_0.5s_ease-in-out]">
              <svg
                className="w-10 h-10 text-rose-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="3"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </div>
          )}
        </div>

        {/* Content */}
        <h1 className="text-3xl font-bold tracking-tight mb-2 text-transparent bg-clip-text bg-linear-to-br from-white to-white/60">
          {status === 'loading' && 'Authenticating'}
          {status === 'success' && 'Verification Complete'}
          {status === 'error' && 'Verification Failed'}
          {status === 'idle' && 'System Online'}
        </h1>

        <p className="text-slate-400 text-sm md:text-base leading-relaxed mb-8">
          {message}
        </p>

        {status === 'success' && (
          <div className="w-full bg-white/5 border border-emerald-500/30 text-emerald-100 font-medium py-4 px-6 rounded-xl">
            You can now safely close this window and return to the CuanBuddy app to login.
          </div>
        )}

        {status === 'error' && (
          <div className="w-full bg-white/5 border border-rose-500/30 text-rose-100 font-medium py-4 px-6 rounded-xl">
            Please request a new verification link from the CuanBuddy mobile app.
          </div>
        )}

        {status === 'idle' && (
          <div className="w-full bg-white/5 border border-blue-500/30 text-blue-100 font-medium py-4 px-6 rounded-xl">
            Waiting for a secure token to proceed.
          </div>
        )}

        {/* Decorative footer */}
        <div className="mt-8 text-xs text-slate-500 font-medium tracking-widest uppercase">
          CuanBuddy Security
        </div>
      </div>
    </div>
  );
}

export default App;
