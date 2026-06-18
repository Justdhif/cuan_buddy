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
    <section id="testimonials" className="py-24 bg-background">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t('testi.title')}</h2>
          <div className="w-24 h-1.5 bg-gradient-to-r from-accent to-primary mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {reviews.map((review, i) => (
            <div key={i} className="p-8 rounded-3xl bg-card border border-border shadow-sm hover:shadow-xl hover:-translate-y-2 transition-all duration-300">
              <div className="flex text-accent mb-6">
                {[...Array(review.rating)].map((_, j) => <Star key={j} size={20} fill="currentColor" />)}
              </div>
              <p className="text-foreground/80 italic mb-8 font-medium">"{review.text}"</p>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary shadow-inner"></div>
                <div>
                  <h4 className="font-bold text-lg">{review.name}</h4>
                  <p className="text-sm text-foreground/60 font-medium">{review.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
