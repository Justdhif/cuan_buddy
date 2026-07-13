import Navbar from './components/Navbar';
import HeroSection from './components/HeroSection';
import SocialProof from './components/SocialProof';
import ProblemSolution from './components/ProblemSolution';
import FeaturesSection from './components/FeaturesSection';
import AIAssistant from './components/AIAssistant';
import AppShowcase from './components/AppShowcase';
import HowItWorksSection from './components/HowItWorksSection';
import SecurityPrivacy from './components/SecurityPrivacy';
import SharedFinance from './components/SharedFinance';
import TestimonialsSection from './components/TestimonialsSection';
import FAQSection from './components/FAQSection';
import DownloadCTA from './components/DownloadCTA';
import Footer from './components/Footer';

function App() {
  return (
    <div className="min-h-screen font-sans bg-white text-ink selection:bg-primary selection:text-black">
      <Navbar />
      <main>
        <HeroSection />
        <SocialProof />
        <ProblemSolution />
        <FeaturesSection />
        <AIAssistant />
        <AppShowcase />
        <HowItWorksSection />
        <SecurityPrivacy />
        <SharedFinance />
        <TestimonialsSection />
        <FAQSection />
        <DownloadCTA />
      </main>
      <Footer />
    </div>
  );
}

export default App;
export {};
