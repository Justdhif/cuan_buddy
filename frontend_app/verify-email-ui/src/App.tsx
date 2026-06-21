import { useEffect, useState } from "react";

function App() {
  const token = new URLSearchParams(window.location.search).get("token");
  const [status, setStatus] = useState<"loading" | "idle" | "success" | "error">(token ? "loading" : "idle");
  const [message, setMessage] = useState(token ? "Verifying your secure token..." : "CuanBuddy Web Services are running successfully. This portal is used for secure email verifications.");

  useEffect(() => {
    if (!token) return;

    const verifyEmail = async () => {
      try {
        const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';
        const response = await fetch(`${backendUrl}/api/auth/verify?token=${token}`);
        const data = await response.json();

        if (response.ok) {
          setStatus("success");
          setMessage(data.message || "Your account has been successfully verified!");
        } else {
          setStatus("error");
          setMessage(data.message || "Verification link is invalid or has expired.");
        }
      } catch {
        setStatus("error");
        setMessage("Network error. Unable to securely reach the verification server.");
      }
    };

    // Add artificial delay for aesthetic loading effect
    setTimeout(() => {
      verifyEmail();
    }, 1500);
  }, [token]);

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-background-dark font-sans text-text-primary-dark relative overflow-hidden px-4">
      {/* Premium Dynamic Background Effects */}
      <div className="absolute top-[-10%] left-[-10%] w-[40rem] h-[40rem] bg-primary/20 rounded-full blur-[120px] pointer-events-none animate-pulse" style={{ animationDuration: '4s' }} />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40rem] h-[40rem] bg-secondary/10 rounded-full blur-[120px] pointer-events-none animate-pulse" style={{ animationDuration: '6s' }} />

      {/* Main Glassmorphism Container */}
      <div className="relative w-full max-w-md backdrop-blur-2xl bg-surface-dark/60 border border-border-dark/50 rounded-3xl p-8 md:p-10 shadow-[0_20px_50px_rgba(0,0,0,0.5)] flex flex-col items-center text-center transition-all duration-700 ease-out transform translate-y-0 hover:shadow-[0_20px_60px_rgba(167,139,250,0.1)]">
        
        {/* Transparent Logo Icon */}
        <div className="mb-6 relative group">
          <div className="absolute inset-0 bg-primary blur-2xl opacity-20 group-hover:opacity-40 transition-opacity duration-500 rounded-full"></div>
          <img 
            src="/app_icon_transparent.png" 
            alt="CuanBuddy Logo" 
            className="w-20 h-20 md:w-24 md:h-24 object-contain relative z-10 drop-shadow-[0_0_15px_rgba(167,139,250,0.4)] transition-transform duration-500 hover:scale-105"
          />
        </div>

        {/* Status Indicators */}
        <div className="mb-8 relative h-16 flex items-center justify-center">
          {status === "loading" && (
            <div className="flex flex-col items-center">
              <div className="w-12 h-12 rounded-full border-[3px] border-border-dark border-t-primary animate-spin"></div>
            </div>
          )}

          {status === 'success' && (
            <div className="w-14 h-14 rounded-full bg-success/10 flex items-center justify-center border border-success/30 shadow-[0_0_30px_rgba(74,222,128,0.3)] animate-[bounce_1s_ease-in-out]">
              <svg className="w-7 h-7 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" />
              </svg>
              {/* Sparkle effects */}
              <div className="absolute -top-1 -right-1 w-3 h-3 bg-success rounded-full animate-ping" />
              <div className="absolute -bottom-1 -left-1 w-2 h-2 bg-success rounded-full animate-ping delay-150" />
            </div>
          )}

          {status === 'idle' && (
            <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center border border-primary/30 shadow-[0_0_30px_rgba(167,139,250,0.2)] animate-[pulse_3s_ease-in-out_infinite]">
              <svg className="w-7 h-7 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
          )}

          {status === "error" && (
            <div className="w-14 h-14 rounded-full bg-danger/10 flex items-center justify-center border border-danger/30 shadow-[0_0_30px_rgba(251,113,133,0.3)] animate-[shake_0.5s_ease-in-out]">
              <svg className="w-7 h-7 text-danger" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          )}
        </div>

        {/* Content */}
        <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight mb-3 text-transparent bg-clip-text bg-gradient-to-r from-white via-primary-light to-secondary-light drop-shadow-sm">
          {status === 'loading' && 'Authenticating...'}
          {status === 'success' && 'Verification Complete'}
          {status === 'error' && 'Verification Failed'}
          {status === 'idle' && 'Secure Portal'}
        </h1>

        <p className="text-text-secondary-dark text-sm md:text-base leading-relaxed mb-8 px-2">
          {message}
        </p>

        {status === 'success' && (
          <div className="w-full bg-success/5 border border-success/20 text-success-light font-medium py-3 px-6 rounded-2xl shadow-inner backdrop-blur-sm transition-all hover:bg-success/10">
            You can now safely close this window and return to the CuanBuddy app to login.
          </div>
        )}

        {status === 'error' && (
          <div className="w-full bg-danger/5 border border-danger/20 text-danger font-medium py-3 px-6 rounded-2xl shadow-inner backdrop-blur-sm transition-all hover:bg-danger/10">
            Please request a new verification link from the CuanBuddy mobile app.
          </div>
        )}

        {status === 'idle' && (
          <div className="w-full bg-primary/5 border border-primary/20 text-primary-light font-medium py-3 px-6 rounded-2xl shadow-inner backdrop-blur-sm">
            Waiting for a secure token to proceed.
          </div>
        )}

        {/* Decorative footer */}
        <div className="mt-10 flex items-center justify-center space-x-2 text-xs text-text-secondary-dark/60 font-semibold tracking-widest uppercase">
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
          </svg>
          <span>Secured by CuanBuddy</span>
        </div>
      </div>
    </div>
  );
}

export default App;
