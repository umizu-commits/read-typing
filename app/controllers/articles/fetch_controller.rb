module Articles
  class FetchController < ApplicationController
    def create
      fetch_result = ArticleHtmlFetcher.new(params[:url]).call
      unless fetch_result.success?
        render json: { error: fetch_result.error_message }, status: :unprocessable_entity
        return
      end

      extract_result = ArticleBodyExtractor.new(fetch_result.html).call
      unless extract_result.success?
        render json: { error: extract_result.error_message }, status: :unprocessable_entity
        return
      end

      preprocess_result = TypingTextPreprocessor.new(extract_result.body).call
      unless preprocess_result.success?
        render json: { error: preprocess_result.error_message }, status: :unprocessable_entity
        return
      end

      render json: { body: preprocess_result.body, title: extract_result.title }
    end
  end
end
