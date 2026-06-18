import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, sql, and } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { categories } from '../database/schema';

import { formatPaginatedResponse } from '../common/utils/formatter.util';

@Injectable()
export class CategoriesService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async findAll(userId: string, query: any) {
    const { page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.categories.findMany({
      where: eq(categories.userId, userId),
      limit: Number(limit),
      offset: offset,
    });

    const countData = await this.db.select({ count: sql`count(*)` })
      .from(categories)
      .where(eq(categories.userId, userId));
    const totalCount = Number(countData[0].count);
    return formatPaginatedResponse(data, totalCount, Number(page), Number(limit));
  }

  async findOne(userId: string, slug: string) {
    const category = await this.db.query.categories.findFirst({
      where: and(eq(categories.slug, slug), eq(categories.userId, userId)),
    });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  async create(userId: string, createCategoryDto: any) {
    let slug = createCategoryDto.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    
    // Check if slug exists for this user
    const existing = await this.db.query.categories.findFirst({
      where: and(eq(categories.slug, slug), eq(categories.userId, userId)),
    });
    if (existing) {
      slug = `${slug}-${Date.now()}`;
    }

    const [newCategory] = await this.db.insert(categories).values({
      ...createCategoryDto,
      userId,
      slug,
    }).returning();
    return newCategory;
  }

  async update(userId: string, slug: string, updateCategoryDto: any) {
    const category = await this.findOne(userId, slug);
    const [updated] = await this.db.update(categories)
      .set({ ...updateCategoryDto, updatedAt: new Date() })
      .where(eq(categories.id, category.id))
      .returning();
    return updated;
  }

  async remove(userId: string, slug: string) {
    const category = await this.findOne(userId, slug);
    await this.db.delete(categories).where(eq(categories.id, category.id));
    return { message: 'Category removed successfully' };
  }
}
