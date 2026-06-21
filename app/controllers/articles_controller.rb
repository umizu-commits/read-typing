class ArticlesController < ApplicationController
  def create
    form = case params[:source_type]
    when "text"
             ArticleTextForm.new(body: params[:body], title: params[:title], user: current_user)
    else
             ArticleForm.new(url: params[:url], user: current_user)
    end

    if form.save
      redirect_to typing_path(article_id: form.article.id)
    else
      redirect_to root_path, alert: form.errors.full_messages.first
    end
  end

  def index
    authorize Article # ArticlePolicy#index? を呼ぶ（未ログインなら弾く）
    @articles = policy_scope(Article).order(created_at: :desc).page(params[:page]).per(20)  # Scope#resolve を呼ぶ（自分の記事だけ取得）
  end

  def destroy
    @article = Article.find(params[:id])
    authorize @article # ArticlePolicy#destroy? を呼ぶ（他人の記事なら弾く）
    @article.destroy
    redirect_to articles_path, notice: "記事を削除しました"
  end
end
