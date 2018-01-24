import Quote from 'discourse/lib/quote';
import Composer from 'discourse/models/composer';
import Post from 'discourse/models/post';
import property from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeDevlog(api) {

  api.includePostAttributes('devlog_post');

  api.decorateWidget('post:after', function (dec) {
    var post = dec.getModel();
    return "Hello" + post.devlog_post;
  });

  api.modifyClass('model:composer', {

    devlog_posting: function() {
      if(this.get('devlogPosting') == 'post') {
        return '<h2>New devlog post</h2>';
      }
    }.property('devlogPosting'),

    save(opts) {
      const devlogPosting = this.get('devlogPosting');

      if(devlogPosting && this.get('topic.can_create_devlog_post')) {

        // change category may result in some effect for topic featured link
        if (!this.get('canEditTopicFeaturedLink')) {
          this.set('featuredLink', null);
        }

        const postStream = this.get("topic.postStream");

        const setdevlog = function (res) {
          const post_id = res.responseJson.post.id;
          const post = postStream.findLoadedPost(post_id);
          const rebake = () => post.rebake();
          ajax("/devlog-post/" + post_id + "/set" + devlogPosting, { type: "PUT" })
            .then(rebake)
            .catch(popupAjaxError);
          return res;
        };
        return this.createPost(opts).then(setdevlog);
      } else {
        return this._super(opts);
      }
    }
  });

  api.modifyClass('controller:topic', {

    updateDevlog(post, method) {
      const rebake = () => post.rebake();
      return ajax("/devlog-post/" + post.get("id") + "/" + method, { type: "PUT" })
        .then(rebake)
        .catch(popupAjaxError);
    },

    actions: {

      replyToPost(post) {
        this._super(post);
        const composerController = this.get('composer');
        composerController.set('model.devlogPosting', 'reply');
      },

      postDevlog(post) {
        this.actions.replyToPost.call(this, post);
        const composerController = this.get('composer');
        composerController.set('model.devlogPosting', 'post');
        return false;
      },

      setDevlogPost(post) {
        return this.updateDevlog(post, "setpost");
      },

      setDevlogReply(post) {
        return this.updateDevlog(post, "setreply");
      }
    }
  });

};

export default {
  name: "extend-for-devlog",

  initialize() {
    withPluginApi('0.8.15', initializeDevlog);
  }
};