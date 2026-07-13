import { useTranslation } from 'react-i18next';
import { Star } from 'lucide-react';

export default function TestimonialsSection() {
  const { t } = useTranslation();

  const reviews = [
    { name: "Andi R.", role: "Student", text: "CuanBuddy has completely transformed how I manage my monthly allowance. Highly recommended!", rating: 5 },
    { name: "Siti M.", role: "Freelancer", text: "The AI advisor is incredibly helpful. It feels like having a financial planner in my pocket.", rating: 5 },
    { name: "Budi P.", role: "Entrepreneur", text: "Setting budgets has never been this easy and visually appealing. The UI is just gorgeous.", rating: 5 }
  ];

  return (
    <section id="testimonials" className="py-24 bg-canvas-soft dark:bg-[#0f1025] transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl">{t('testi.title')}</h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {reviews.map((review, i) => (
            <div 
              key={i} 
              className="p-8 rounded-[12px] bg-canvas dark:bg-brand-dark-900 border border-hairline dark:border-hairline/10 shadow-level-1 hover:shadow-level-2 hover:-translate-y-1 transition-all duration-300 flex flex-col justify-between"
            >
              <div>
                <div className="flex text-primary dark:text-primary-soft mb-6 gap-0.5">
                  {[...Array(review.rating)].map((_, j) => <Star key={j} size={16} fill="currentColor" stroke="none" />)}
                </div>
                <p className="text-ink-secondary dark:text-canvas-soft/80 italic mb-8 font-light text-[15px] leading-relaxed">
                  "{review.text}"
                </p>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-linear-to-br from-primary/20 to-primary-soft/20 dark:from-primary/40 dark:to-primary-soft/40 flex items-center justify-center text-primary dark:text-primary-soft font-bold text-sm">
                  {review.name.charAt(0)}
                </div>
                <div>
                  <h4 className="font-semibold text-ink dark:text-canvas text-sm">{review.name}</h4>
                  <p className="text-[12px] text-ink-mute dark:text-canvas-soft/60 font-light">{review.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
