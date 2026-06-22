class ArticlesController < ApplicationController
  def create
    form = case params[:source_type]
    when "text"
      ArticleTextForm.new(body: params[:body], title: params[:title], category: params[:category], tag_names: params[:tag_names], user: current_user)
    else
      ArticleForm.new(url: params[:url], category: params[:category], tag_names: params[:tag_names], user: current_user)
    end

    if form.save
      redirect_to typing_path(article_id: form.article.id)
    else
      redirect_to root_path, alert: form.errors.full_messages.first
    end
  end

  def index
    authorize Article # ArticlePolicy#index? を呼ぶ（未ログインなら弾く）
    articles = policy_scope(Article)
    articles = articles.search_by_keyword(params[:q].strip) if params[:q].present?
    articles = articles.by_category(params[:category])
    articles = articles.by_tag(params[:tag]) if params[:tag].present?
    articles = articles.sorted_by(params[:sort].presence || "newest")
    @articles = articles.includes(:tags).page(params[:page]).per(20)
    @current_sort = params[:sort].presence || "newest"
    @current_keyword = params[:q].to_s.strip
    @current_category = params[:category].to_s
    @current_tag = params[:tag].to_s
  end

  def destroy
    @article = Article.find(params[:id])
    authorize @article # ArticlePolicy#destroy? を呼ぶ（他人の記事なら弾く）
    @article.destroy
    redirect_to articles_path, notice: "記事を削除しました"
  end
end
