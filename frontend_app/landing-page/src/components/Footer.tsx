import { useTranslation } from 'react-i18next';
import { Globe, Mail, Twitter, Instagram, Linkedin } from 'lucide-react';

export default function Footer() {
  const { t } = useTranslation();
  
  return (
    <footer className="bg-card border-t border-border pt-20 pb-10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-16">
          <div className="md:col-span-1">
            <div className="flex items-center gap-2 mb-6">
              <img src="/app_icon_transparent.png" alt="CuanBuddy" className="h-8 w-8" />
              <span className="font-bold text-xl text-primary">CuanBuddy</span>
            </div>
            <p className="text-foreground/70 mb-6 leading-relaxed">
              Your smart financial companion to track expenses, manage budgets, and achieve savings goals effortlessly.
            </p>
            <div className="flex gap-4">
              <a href="#" className="text-foreground/60 hover:text-primary transition-colors"><Twitter size={20} /></a>
              <a href="#" className="text-foreground/60 hover:text-accent transition-colors"><Instagram size={20} /></a>
              <a href="#" className="text-foreground/60 hover:text-secondary transition-colors"><Linkedin size={20} /></a>
            </div>
          </div>
          
          <div>
            <h3 className="font-bold text-foreground mb-6">Product</h3>
            <ul className="space-y-4">
              <li><a href="#features" className="text-foreground/70 hover:text-primary transition-colors">Features</a></li>
              <li><a href="#how" className="text-foreground/70 hover:text-primary transition-colors">How It Works</a></li>
              <li><a href="#testimonials" className="text-foreground/70 hover:text-primary transition-colors">Testimonials</a></li>
              <li><a href="#faq" className="text-foreground/70 hover:text-primary transition-colors">FAQ</a></li>
            </ul>
          </div>
          
          <div>
            <h3 className="font-bold text-foreground mb-6">Company</h3>
            <ul className="space-y-4">
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">About Us</a></li>
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Careers</a></li>
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Blog</a></li>
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Contact</a></li>
            </ul>
          </div>
          
          <div>
            <h3 className="font-bold text-foreground mb-6">Legal</h3>
            <ul className="space-y-4">
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Privacy Policy</a></li>
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Terms of Service</a></li>
              <li><a href="#" className="text-foreground/70 hover:text-primary transition-colors">Cookie Policy</a></li>
            </ul>
          </div>
        </div>
        
        <div className="pt-8 border-t border-border flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-foreground/50 font-medium text-sm">
            &copy; {new Date().getFullYear()} CuanBuddy. {t('footer.rights')}
          </div>
          <div className="flex gap-6 text-sm text-foreground/50">
            <span className="flex items-center gap-2"><Globe size={16} /> Global (EN)</span>
            <span className="flex items-center gap-2"><Mail size={16} /> support@cuanbuddy.com</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
