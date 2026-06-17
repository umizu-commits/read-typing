class TypingController < ApplicationController
    def show
      return if params[:article_id].blank?
      article = Article.find_by(id: params[:article_id])

      if article.nil?
        redirect_to root_path, alert: "タイピング対象の記事が見つかりません"
        return
      end

      if user_signed_in?
        unless article.user_id == current_user.id
          redirect_to root_path, alert: "この記事にはアクセスできません"
          return
        end
      else
        unless article.user_id.nil?
          redirect_to root_path, alert: "この記事にはアクセスできません"
          return
        end
      end

      @typing_text = article.body
    end

    def result
    end

    # ログイン中であるか確認、保存してJSONを返す
    def save_result
        # 未ログインならスキップ
        unless user_signed_in?
            session[:pending_typing_result] = typing_result_params.to_h
            render json: { status: "skipped" }
            return
        end

        result = current_user.typing_results.create(typing_result_params)

        # 保存結果に応じてレスポンスを返す
        if result.persisted?
            render json: { status: "saved" }
        else
            render json: { status: "failed" }
        end
    end

    private
    def typing_result_params
        params.permit(:wpm, :cpm, :accuracy, :miss_count, :elapsed_time, :article_text)
    end
end
