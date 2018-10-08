import Quote from 'discourse/lib/quote';
import Composer from 'discourse/models/composer';
import Post from 'discourse/models/post';
import property from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeDevlog(api) {

  api.includePostAttributes('devlog_post');

  api.addPostClassesCallback((atts) => {
    if (atts.devlog_post == 'post') return ["devlog-post"];
  })

  // This is for testing purposes.
/*
  api.decorateWidget('post:after', function (dec) {
    var post = dec.getModel();
    return `[devlog ${post.devlog_post}]`;
  });
*/
  api.modifyClass('model:composer', {

    devlog_posting: function() {
      if(this.get('devlogPosting') == 'post') {
        return '<h2>New devlog post</h2>';
      }
    }.property('devlogPosting'),

    save(opts) {
      const result = this._super(opts);
      const isDevlogEnabled = this.get("topic.devlog_enabled")

      if (result && ! this.get('editingPost') && isDevlogEnabled) {
        const devlogPosting = this.get('devlogPosting');
        const postStream = this.get("topic.postStream");

        result.then(function(res) {
          // If this is the first post in a devlog category topic, or
          // if devlogPosting is "post", try making this a post, otherwise
          // try making it a reply.
          let method = "tryreply";
          if (res.responseJson.post.post_number === 1 || devlogPosting === "post") {
            method = "trypost";
          }
          const topic_id = res.responseJson.post.topic_id;
          const post_id = res.responseJson.post.id;

          let rebake = function () {};
          if (postStream) {
            const post = postStream.findLoadedPost(post_id);
            rebake = () => post.rebake();
          }

          ajax(`/devlog-post/${topic_id}/${post_id}/${method}`, { type: "PUT" })
            .then(rebake)
            .catch(popupAjaxError);

          return res;
        });
      }

      return result;
    }
  });

  api.modifyClass('controller:topic', {

    updateDevlog(post, method) {
      const rebake = () => post.rebake();
      const post_id = post.get("id");
      const topic_id = post.get("topic_id");
      return ajax(`/devlog-post/${topic_id}/${post_id}/${method}`, { type: "PUT" })
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
        return this.updateDevlog(post, "trypost");
      },

      setDevlogReply(post) {
        return this.updateDevlog(post, "tryreply");
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
