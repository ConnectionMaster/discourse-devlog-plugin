import property from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default {
  name: 'extend-category-for-devlog',
  before: 'inject-discourse-objects',
  initialize() {

    Category.reopen({

      @property('custom_fields.devlog_posting')
      devlog_posting: {
        get(devlogField) {
          return devlogField === "true";
        },
        set(value) {
          value = value ? "true" : "false";
          this.set("custom_fields.devlog_posting", value);
          return value;
        }
      }
    });
  }
};