module Articles
  class FetchController < ApplicationController
    def create
      content_result = ArticleContentFetcher.new(params[:url]).call
      unless content_result.success?
        render json: { error: content_result.error_message }, status: :unprocessable_entity
        return
      end

      render json: { body: content_result.body, title: content_result.title }
    end
  end
end
