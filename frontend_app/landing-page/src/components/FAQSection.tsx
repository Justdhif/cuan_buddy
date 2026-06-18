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
    <section id="faq" className="py-24 bg-card border-y border-border/50">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t('faq.title')}</h2>
          <div className="w-24 h-1.5 bg-primary mx-auto rounded-full"></div>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, i) => (
            <div key={i} className={`border border-border rounded-2xl overflow-hidden bg-background transition-all duration-300 ${openIndex === i ? 'shadow-md border-primary/30' : ''}`}>
              <button 
                className="w-full px-6 py-5 flex justify-between items-center text-left font-bold text-lg hover:bg-card transition-colors"
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
              >
                {faq.q}
                <div className={`p-1 rounded-full ${openIndex === i ? 'bg-primary/10 text-primary' : 'text-foreground/50'}`}>
                  <ChevronDown size={20} className={`transform transition-transform duration-300 ${openIndex === i ? 'rotate-180' : ''}`} />
                </div>
              </button>
              <div 
                className={`px-6 text-foreground/70 font-medium overflow-hidden transition-all duration-300 ease-in-out ${openIndex === i ? 'max-h-40 pb-5 opacity-100' : 'max-h-0 opacity-0'}`}
              >
                {faq.a}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
