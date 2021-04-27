import { generateId, RxCollection } from 'rxdb';

export class Collection<T> {
  constructor(private readonly collection: RxCollection) {}

  createItem(data: Partial<T>): Promise<T> {
    const id = (data as any).id || generateId();
    console.log({ id });
    return this.collection.insert({ ...data, id }).then((res) => this.findOne(res.id));
  }

  deleteItem(itemId: string): Promise<boolean> {
    return this.collection
      ?.findOne({ selector: { id: itemId } })
      .remove()
      .then((res) => !!res);
  }

  findMany(): Promise<T[]> {
    return this.collection
      ?.find()
      .exec()
      .then((items) => items.map((item) => item.toJSON() || []));
  }

  findOne(itemId: string): Promise<T> {
    return this.collection
      ?.findOne({ selector: { id: itemId } })
      .exec()
      .then((res) => res?.toJSON());
  }

  updateItem(id: string, data: Partial<T>): Promise<T> {
    return this.collection.upsert({ ...data, id }).then((res) => this.findOne(res.id));
  }
}
