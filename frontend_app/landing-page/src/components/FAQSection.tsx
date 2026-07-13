import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import { ChevronDown } from 'lucide-react';

export default function FAQSection() {
  const { t } = useTranslation();
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    { q: "Is CuanBuddy free to use?", a: "Yes! The core features of CuanBuddy will always be free." },
    { q: "How secure is my data?", a: "We use bank-level encryption. Your financial data is securely stored and protected." },
    { q: "Can I use it offline?", a: "Absolutely. CuanBuddy works offline and syncs automatically when you're back online." },
    { q: "Is the AI advisor included in the free plan?", a: "Yes, basic AI insights are included for all users to help you manage your finances better." }
  ];

  return (
    <section id="faq" className="py-24 bg-canvas dark:bg-ink transition-colors duration-300">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl">{t('faq.title')}</h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, i) => {
            const isOpen = openIndex === i;
            return (
              <div 
                key={i} 
                className={`border rounded-[12px] overflow-hidden bg-canvas dark:bg-brand-dark-900 transition-all duration-350 ${
                  isOpen 
                    ? 'border-primary/30 dark:border-primary-soft/30 shadow-level-1' 
                    : 'border-hairline dark:border-hairline/10'
                }`}
              >
                <button 
                  className="w-full px-6 py-5 flex justify-between items-center text-left font-medium text-ink dark:text-canvas text-base hover:bg-canvas-soft dark:hover:bg-brand-dark-900/50 transition-colors"
                  onClick={() => setOpenIndex(isOpen ? null : i)}
                >
                  {faq.q}
                  <div className={`p-1.5 rounded-full transition-colors duration-250 ${
                    isOpen ? 'bg-primary/10 dark:bg-primary-soft/10 text-primary dark:text-primary-soft' : 'text-ink-mute/50'
                  }`}>
                    <ChevronDown size={16} className={`transform transition-transform duration-300 ${isOpen ? 'rotate-180' : ''}`} />
                  </div>
                </button>
                <div 
                  className={`px-6 font-light text-ink-secondary dark:text-canvas-soft/80 text-[15px] overflow-hidden transition-all duration-300 ease-in-out ${
                    isOpen ? 'max-h-40 pb-5 opacity-100' : 'max-h-0 opacity-0 pointer-events-none'
                  }`}
                >
                  <p className="leading-relaxed">{faq.a}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
