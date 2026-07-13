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
    <section id="faq" className="py-24 bg-white border-b border-hairline/60 transition-colors duration-300">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Stripe Header */}
        <div className="text-center mb-16">
          <span className="text-[13px] font-semibold text-primary uppercase tracking-widest block mb-3">FAQ</span>
          <h2 className="text-3xl md:text-[38px] font-extrabold text-ink tracking-tight mb-4">{t('faq.title')}</h2>
          <div className="w-12 h-1 bg-primary mx-auto rounded-full"></div>
        </div>

        {/* Stripe Clean Accordions */}
        <div className="space-y-4">
          {faqs.map((faq, i) => {
            const isOpen = openIndex === i;
            return (
              <div 
                key={i} 
                className={`border rounded-[12px] overflow-hidden bg-white transition-all duration-300 ${
                  isOpen ? 'border-primary/40 shadow-sm' : 'border-hairline'
                }`}
              >
                <button 
                  className="w-full px-6 py-5 flex justify-between items-center text-left font-bold text-[16px] text-ink hover:bg-[#f6f9fc] transition-colors"
                  onClick={() => setOpenIndex(isOpen ? null : i)}
                >
                  {faq.q}
                  <div className={`p-1.5 rounded-full transition-colors duration-250 ${
                    isOpen ? 'bg-primary/10 text-primary' : 'text-ink-mute/40'
                  }`}>
                    <ChevronDown size={16} className={`transform transition-transform duration-300 ${isOpen ? 'rotate-180' : ''}`} />
                  </div>
                </button>
                <div 
                  className={`px-6 text-ink-mute text-[14px] overflow-hidden transition-all duration-300 ease-in-out ${
                    isOpen ? 'max-h-40 pb-5 opacity-100' : 'max-h-0 opacity-0 pointer-events-none'
                  }`}
                >
                  <p className="leading-relaxed font-light">{faq.a}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
