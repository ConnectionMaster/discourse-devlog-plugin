import Quote from 'discourse/lib/quote';
import Composer from 'discourse/models/composer';
import Post from 'discourse/models/post';
import computed from 'ember-addons/ember-computed-decorators';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeDevlog(api) {

  api.includePostAttributes('devlog_post');

  api.decorateWidget('post:after', function (dec) {
    var post = dec.getModel();
    return "Hello" + post.devlog_post;
  });

  api.modifyClass('model:composer', {
    devlog_posting: function() {
      var reply = this.get('post.post_number');
      if(!reply) {
        return '<h2>New devlog post</h2>';
      }
    }.property('post.post_number'),
  });

};

export default {
  name: "extend-for-devlog",

  initialize() {
    withPluginApi('0.8.15', initializeDevlog);
  }
};