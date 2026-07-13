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
    <section id="testimonials" className="py-24 bg-white text-airbnb-ink border-b border-airbnb-hairline transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <span className="text-[12px] font-bold text-airbnb-primary uppercase tracking-widest block mb-2">REVIEWS</span>
          {/* Airbnb display-xl modest heading (28px) */}
          <h2 className="font-sans text-[28px] font-bold tracking-tight text-airbnb-ink">
            {t('testi.title')}
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {reviews.map((review, i) => (
            <div 
              key={i} 
              className="p-6 rounded-[14px] bg-white border border-airbnb-hairline hover:shadow-airbnb-float transition-all duration-300 flex flex-col justify-between"
            >
              <div>
                {/* Airbnb uses ink color for rating stars (not yellow) */}
                <div className="flex text-airbnb-ink mb-4 gap-0.5">
                  {[...Array(review.rating)].map((_, j) => (
                    <Star key={j} size={15} fill="currentColor" stroke="none" />
                  ))}
                </div>
                <p className="text-airbnb-body italic mb-6 font-light text-[15px] leading-relaxed">
                  "{review.text}"
                </p>
              </div>
              <div className="flex items-center gap-3">
                {/* Avatar circle (36px size) */}
                <div className="w-9 h-9 rounded-full bg-airbnb-surface-soft flex items-center justify-center text-airbnb-primary font-bold text-sm">
                  {review.name.charAt(0)}
                </div>
                <div>
                  <h4 className="font-semibold text-airbnb-ink text-sm">{review.name}</h4>
                  <p className="text-[12px] text-airbnb-muted font-light">{review.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
