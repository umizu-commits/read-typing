class TypingController < ApplicationController
    def show
    end

    def result
    end

    # ログイン中であるか確認、保存してJSONを返す
    def save_result
        # 未ログインならスキップ
        unless user_signed_in?
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
