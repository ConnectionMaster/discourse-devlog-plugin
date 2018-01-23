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
    Post.register_custom_field_type('devlog_post', :boolean)

    TopicList.preloaded_custom_fields << "devlog_enabled"

    add_to_serializer(:topic_view, :devlog_enabled, false) do
      object.topic.category.custom_fields['devlog_enabled']
    end

    add_to_serializer(:topic_view, :can_create_devlog_post, false) do
      first_poster = object.topic.first_post.user_id
      current_user = scope.user.id
      object.topic.category.custom_fields['devlog_enabled'] && first_poster == current_user
    end

    require_dependency 'post_serializer'
    class ::PostSerializer
      attributes :devlog_post
      def include_devlog_post?
        object.topic.category.custom_fields['devlog_enabled']
      end
      def devlog_post
        if object.custom_fields['devlog_post'].nil? then
          false
        else
          object.custom_fields['devlog_post']
        end
      end
    end

    require_dependency "application_controller"

    class DiscourseDevlog::UpdateController < ::ApplicationController
      requires_plugin PLUGIN_NAME

      def setdevlogpost(post_id, value)
        post = Post.find_by(id: post_id)
        DistributedMutex.synchronize("devlog-#{post.id}") do
          post.custom_fields['devlog_post'] = value
          post.save_custom_fields(true)
          render json: { post_id => value }
        end
      end

      def set
        post_id   = params.require(:post_id)
        setdevlogpost(post_id, true)
      end

      def clear
        post_id   = params.require(:post_id)
        setdevlogpost(post_id, false)
      end
    end

    DiscourseDevlog::Engine.routes.draw do
      put ":post_id/set" => 'update#set'
      put ":post_id/clear" => 'update#clear'
    end

    Discourse::Application.routes.append do
      mount ::DiscourseDevlog::Engine, at: "devlog-post"
    end
  end
end