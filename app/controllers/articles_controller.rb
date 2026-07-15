class ArticlesController < ApplicationController
  def create
    form = case params[:source_type]
    when "text"
      ArticleTextForm.new(body: params[:body], title: params[:title], category: params[:category], tag_names: params[:tag_names], user: current_user)
    else
      ArticleForm.new(url: params[:url], category: params[:category], tag_names: params[:tag_names], user: current_user)
    end

    if form.save
      AchievementGrantService.new(current_user).call(context: :article_saved) if user_signed_in?
      if params[:save_only] == "true"
        redirect_to articles_path, notice: "記事を保存しました"
      else
        redirect_to typing_path(article_id: form.article.id)
      end
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
    @current_favorites_only = params[:favorites_only] == "true"
    articles = articles.merge(current_user.favorite_articles) if @current_favorites_only
    articles = articles.sorted_by(params[:sort].presence || "newest")
    @articles = articles.includes(:tags).page(params[:page]).per(20)
    @current_sort = params[:sort].presence || "newest"
    @current_keyword = params[:q].to_s.strip
    @current_category = params[:category].to_s
    @current_tag = params[:tag].to_s
    @available_tag_names = policy_scope(Article).joins(:tags).distinct.pluck("tags.name").sort
    @favorited_article_ids = current_user.favorites.where(article_id: @articles.select(:id)).pluck(:article_id)
  end

  def show
    @article = Article.find_by!(id: params[:id])
    authorize @article
  end

  def destroy
    @article = Article.find(params[:id])
    authorize @article # ArticlePolicy#destroy? を呼ぶ（他人の記事なら弾く）
    @article.destroy
    redirect_to articles_path, notice: "記事を削除しました"
  end

  def edit
    @article = Article.find(params[:id])
    authorize @article

    current_tags = @article.tags.map(&:name).join(", ")
    @form = ArticleEditForm.new(
      article: @article,
      params: {
        title:     @article.title,
        body:      @article.body,
        category:  @article.category,
        tag_names: current_tags
      }
    )
  end

  def update
    @article = Article.find(params[:id])
    authorize @article

    @form = ArticleEditForm.new(
      article: @article,
      params:  article_edit_params
    )

    if @form.update
      redirect_to articles_path, notice: "記事を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def favorite
    @article = Article.find(params[:id])
    authorize @article, :favorite?

    favorite = current_user.favorites.find_by(article: @article)

    if favorite
      favorite.destroy
      favorited = false
    else
      begin # 同時リクエストによる競合の場合はそのままお気に入り済みとして扱う
        current_user.favorites.create!(article: @article)
      rescue ActiveRecord::RecordNotUnique
      end
      favorited = true
    end

    render turbo_stream: turbo_stream.replace(
      "favorite-btn-#{@article.id}",
      partial: "articles/favorite_button",
      locals: { article: @article, favorited: favorited }
    )
  end

  private

  def article_edit_params
    params.permit(:title, :body, :category, :tag_names)
  end
end
