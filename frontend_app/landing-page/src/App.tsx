import { ThemeProvider } from './components/ThemeProvider';
import Navbar from './components/Navbar';
import HeroSection from './components/HeroSection';
import TrustedSection from './components/TrustedSection';
import ProblemSolutionSection from './components/ProblemSolutionSection';
import FeaturesSection from './components/FeaturesSection';
import AiAssistantSection from './components/AiAssistantSection';
import ScreenshotsSection from './components/ScreenshotsSection';
import HowItWorksSection from './components/HowItWorksSection';
import SecurityPrivacySection from './components/SecurityPrivacySection';
import SharedFinanceSection from './components/SharedFinanceSection';
import TestimonialsSection from './components/TestimonialsSection';
import FAQSection from './components/FAQSection';
import DownloadCtaSection from './components/DownloadCtaSection';
import Footer from './components/Footer';

function App() {
  return (
    <ThemeProvider defaultTheme="system" storageKey="cuan-buddy-theme">
      <div className="min-h-screen font-sans selection:bg-primary selection:text-black">
        {/* 1. Navbar */}
        <Navbar />
        
        <main>
          {/* 2. Hero */}
          <HeroSection />

          {/* 3. Trusted by / Social Proof */}
          <TrustedSection />

          {/* 4. Problem & Solution */}
          <ProblemSolutionSection />

          {/* 5. Key Features */}
          <FeaturesSection />

          {/* 6. AI Financial Assistant ⭐ */}
          <AiAssistantSection />

          {/* 7. App Screenshots */}
          <ScreenshotsSection />

          {/* 8. How It Works */}
          <HowItWorksSection />

          {/* 9. Security & Privacy ⭐ */}
          <SecurityPrivacySection />

          {/* 10. Shared Finance (fitur unggulan) */}
          <SharedFinanceSection />

          {/* 11. Testimonials */}
          <TestimonialsSection />

          {/* 12. FAQ */}
          <FAQSection />

          {/* 13. Download CTA */}
          <DownloadCtaSection />
        </main>

        {/* 14. Footer */}
        <Footer />
      </div>
    </ThemeProvider>
  );
}

export default App;
