# name: devlog-categories
# about: A plugin for tracking and managing devlog posts
# version: 0.0.1
# authors: Mikael Säker

enabled_site_setting :devlog_categories_enabled

PLUGIN_NAME = "discourse_devlog".freeze

after_initialize do

  if SiteSetting.devlog_categories_enabled then

    module ::DiscourseDevlog
      class Engine < ::Rails::Engine
        engine_name PLUGIN_NAME
        isolate_namespace DiscourseDevlog
      end
    end

    Category.register_custom_field_type('devlog_enabled', :boolean)
    Post.register_custom_field_type('devlog_post', :string)

    TopicList.preloaded_custom_fields << "devlog_enabled"

    add_to_serializer(:topic_list, :devlog_enabled, false) do
      if object.topics.empty? then
        false
      else
        category_id = object.topics[0].category_id
        category = Category.find_by_id(category_id)
        category.nil? ? false : category.custom_fields['devlog_enabled']
      end
    end

    add_to_serializer(:topic_view, :devlog_enabled, false) do
      object.topic.category.custom_fields['devlog_enabled']
    end

    add_to_serializer(:topic_view, :can_create_devlog_post, false) do
      first_poster = object.topic.first_post.user_id
      current_user = scope.user.nil? ? nil : scope.user.id
      object.topic.category.custom_fields['devlog_enabled'] && !current_user.nil? && first_poster == current_user
    end

    add_to_serializer(:post, :devlog_post, false) do
      object.custom_fields['devlog_post']
    end

    require_dependency "application_controller"

    class DiscourseDevlog::UpdateController < ::ApplicationController
      requires_plugin PLUGIN_NAME

      # Try setting devlog_post field on a post if the topic allows it.
      def trysetdevlogpost(topic_id, post_id, value)
        topic = Topic.find_by(id: topic_id)
        if topic.category.custom_fields['devlog_enabled'] then
          post = Post.find_by(id: post_id)
          DistributedMutex.synchronize("devlog-#{post.id}") do
            post.custom_fields['devlog_post'] = value
            post.save_custom_fields(true)
            render json: { post_id => value }
          end
        end
      end

      def trypost
        topic_id   = params.require(:topic_id)
        post_id   = params.require(:post_id)
        trysetdevlogpost(topic_id, post_id, 'post')
      end

      def tryreply
        topic_id   = params.require(:topic_id)
        post_id   = params.require(:post_id)
        trysetdevlogpost(topic_id, post_id, 'reply')
      end
    end

    DiscourseDevlog::Engine.routes.draw do
      put ":topic_id/:post_id/trypost" => 'update#trypost'
      put ":topic_id/:post_id/tryreply" => 'update#tryreply'
    end

    Discourse::Application.routes.append do
      mount ::DiscourseDevlog::Engine, at: "devlog-post"
    end
  end
end