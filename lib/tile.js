'use babel'
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let Tile;

export default Tile = class Tile {
  constructor(item, priority, collection) {
    this.item = item;
    this.priority = priority;
    this.collection = collection;
  }

  getItem() {
    return this.item;
  }

  getPriority() {
    return this.priority;
  }

  destroy() {
    this.collection.splice(this.collection.indexOf(this), 1);
    return atom.views.getView(this.item).remove();
  }
};
