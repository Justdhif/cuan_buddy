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

  async findOne(userId: string, id: string) {
    const category = await this.db.query.categories.findFirst({
      where: and(eq(categories.id, id), eq(categories.userId, userId)),
    });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  async create(userId: string, createCategoryDto: any) {
    const [category] = await this.db.insert(categories).values({
      userId,
      name: createCategoryDto.name,
      emojiIcon: createCategoryDto.emojiIcon,
      colorCode: createCategoryDto.colorCode,
    }).returning();
    return category;
  }

  async update(userId: string, id: string, updateCategoryDto: any) {
    const category = await this.findOne(userId, id);
    
    const [updated] = await this.db.update(categories)
      .set({ ...updateCategoryDto, updatedAt: new Date() })
      .where(and(eq(categories.id, id), eq(categories.userId, userId)))
      .returning();
    return updated;
  }

  async remove(userId: string, id: string) {
    const category = await this.findOne(userId, id);
    
    await this.db.delete(categories)
      .where(and(eq(categories.id, id), eq(categories.userId, userId)));
    return { message: 'Category removed successfully' };
  }
}
