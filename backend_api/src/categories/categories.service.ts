import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { categories } from '../database/schema';

import { formatPaginatedResponse } from '../common/utils/formatter.util';

@Injectable()
export class CategoriesService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async findAll(query: any) {
    const { page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.categories.findMany({
      limit: Number(limit),
      offset: offset,
    });

    const countData = await this.db.select({ count: sql`count(*)` }).from(categories);
    const totalCount = Number(countData[0].count);
    return formatPaginatedResponse(data, totalCount, Number(page), Number(limit));
  }

  async findOne(id: string) {
    const category = await this.db.query.categories.findFirst({
      where: eq(categories.slug, id),
    });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  async create(createCategoryDto: any) {
    const slug = createCategoryDto.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    const [newCategory] = await this.db.insert(categories).values({
      ...createCategoryDto,
      slug,
    }).returning();
    return newCategory;
  }

  async update(id: string, updateCategoryDto: any) {
    const [updated] = await this.db.update(categories)
      .set({ ...updateCategoryDto, updatedAt: new Date() })
      .where(eq(categories.id, id))
      .returning();
    return updated;
  }

  async remove(id: string) {
    await this.db.delete(categories).where(eq(categories.id, id));
    return { message: 'Category removed successfully' };
  }
}
