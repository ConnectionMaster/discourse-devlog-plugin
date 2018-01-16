import computed from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default {
  name: 'extend-category-for-devlog',
  before: 'inject-discourse-objects',
  initialize() {

    Category.reopen({

      @computed('custom_fields.devlog_enabled')
      enable_accepted_answers: {
        get(enableField) {
          return enableField === "true";
        },
        set(value) {
          value = value ? "true" : "false";
          this.set("custom_fields.devlog_enabled", value);
          return value;
        }
      }

    });
  }
};
