import { useTranslation } from "react-i18next";
import { Globe, Mail } from "lucide-react";

export default function Footer() {
  const { t } = useTranslation();

  return (
    <footer className="bg-canvas dark:bg-ink border-t border-hairline/60 dark:border-hairline/10 py-16 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-16">
          <div className="md:col-span-1">
            <div className="flex items-center gap-2 mb-6">
              <img
                src="/app_icon_transparent.png"
                alt="CuanBuddy Logo"
                className="h-7 w-7"
              />
              <span className="font-semibold text-lg text-ink dark:text-canvas tracking-tight">CuanBuddy</span>
            </div>
            <p className="text-ink-mute dark:text-canvas-soft/75 text-[13px] leading-relaxed mb-6 font-light">
              Your smart financial companion to track expenses, manage budgets,
              and achieve savings goals effortlessly.
            </p>
            <div className="flex gap-4">
              <a
                href="#"
                className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors"
                aria-label="Twitter"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-twitter"><path d="M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z"/></svg>
              </a>
              <a
                href="#"
                className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors"
                aria-label="Instagram"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-instagram"><rect width="20" height="20" x="2" y="2" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>
              </a>
              <a
                href="#"
                className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors"
                aria-label="LinkedIn"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="lucide lucide-linkedin"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect width="4" height="12" x="2" y="9"/><circle cx="4" cy="4" r="2"/></svg>
              </a>
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-ink dark:text-canvas text-sm mb-6">Product</h3>
            <ul className="space-y-4 text-[13px]">
              <li>
                <a
                  href="#features"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Features
                </a>
              </li>
              <li>
                <a
                  href="#how"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  How It Works
                </a>
              </li>
              <li>
                <a
                  href="#testimonials"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Testimonials
                </a>
              </li>
              <li>
                <a
                  href="#faq"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  FAQ
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-semibold text-ink dark:text-canvas text-sm mb-6">Company</h3>
            <ul className="space-y-4 text-[13px]">
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  About Us
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Careers
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Blog
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Contact
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-semibold text-ink dark:text-canvas text-sm mb-6">Legal</h3>
            <ul className="space-y-4 text-[13px]">
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Privacy Policy
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Terms of Service
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-ink-mute hover:text-primary dark:hover:text-primary-soft transition-colors font-light"
                >
                  Cookie Policy
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-hairline/60 dark:border-hairline/10 flex flex-col md:flex-row justify-between items-center gap-4 text-[13px] text-ink-mute dark:text-canvas-soft/60">
          <div className="font-light">
            &copy; {new Date().getFullYear()} CuanBuddy. {t("footer.rights")}
          </div>
          <div className="flex gap-6">
            <span className="flex items-center gap-1.5 font-light">
              <Globe size={14} /> Global (EN)
            </span>
            <span className="flex items-center gap-1.5 font-light">
              <Mail size={14} /> support@cuanbuddy.com
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
}
