class JournalsController < ApplicationController
  helper MistakesHelper
  before_action :authenticate_user!
  def index
    # @journals =current_user.journals.order(created_at: :desc)
    @journals =current_user.journals.includes(:journal_correction).order(posted_date: :desc, id: :desc)
  end

  def show
    @journal = current_user.journals.find(params[:id])
    @journal_correction = @journal.journal_correction
    @mistakes = @journal_correction&.mistakes || []
    @previous_journal = current_user.journals
                        .where("posted_date < ? OR (posted_date = ? AND id > ?)", @journal.posted_date, @journal.posted_date, @journal.id)
                        .order(posted_date: :desc, id: :desc).first
    @next_journal = current_user.journals
                    .where("posted_date > ? OR (posted_date = ? AND id > ?)", @journal.posted_date, @journal.posted_date, @journal.id)
                    .order(posted_date: :asc, id: :asc).first
  end

  def new
    @journal = current_user.journals.new(posted_date: Date.current)
  end

  def create
    @journal = current_user.journals.new(journal_params)
    if @journal.invalid?
      flash.now[:alert] = "ジャーナルの作成に失敗しました"
      render :new, status: :unprocessable_entity
      return
    end

      # 1 フォームから本文の文字列を受け取る
      body = params[:journal][:body]
      tone = params[:journal][:tone]

      raise "tone is nil!" if tone.blank?

      # 2 AIへの指示(プロンプト)を作成する(journal_prompt_builder.rbに移動)
      prompt = JournalPromptBuilder.new(body: body, tone: tone).build

      # 3 OpenAI APIクライアントを初期化する
      client = OpenAI::Client.new

      # 4 APIにリクエストを送信する
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [ { role: "user", content: prompt } ],
          response_format: { type: "json_object" },
          temperature: 1.0
        }
      )

      # 5 AIからのJSON応答をパースする
      raw_response = response.dig("choices", 0, "message", "content")
      result = JSON.parse(raw_response)
      Rails.logger.debug "=== result: #{result.inspect}"
      Rails.logger.debug "=== english_feedback: #{result['english_feedback'].inspect}"

      # 6 DBに保存する
      # @journal = current_user.journals.build(
      #   **journal_params  # title, posted_date, mood, body, tone が全部入る
      # )

      if @journal.save

        # 7.添削後の全文をjournal_correctionsに保存する
        # mistakesにデータを保存する
        correction = @journal.create_journal_correction!(
          user_id: current_user.id,
          original_text: body,
          rewritten_text: result["rewritten_text"]
        )

        (result["notes"] || []).each do |note|
          correction.mistakes.create!(
            journal: @journal,
            user: current_user,
            original_text: note["original_text"],
            corrected_text: note["corrected_text"],
            mistake_type: note["mistake_type"],
            explanation: note["explanation"],
            learning_points: note["learning_points"] || {}
          )
        end

        # 7. 添削後の全文と各指摘をmistakesに保存する
        # @journal.mistakes.create!(
        #   user_id: current_user.id,
        #   original_text: body,
        #   corrected_text: result["rewritten_text"],
        #   mistake_type: :overall
        #   )

        # 8 個別の指摘をmistakesに1件ずつ保存する
        #   (result["notes"] || []).each do |note|
        #     @journal.mistakes.create!(
        #       user_id: current_user.id,
        #       original_text: note["original_text"],
        #       corrected_text: note["corrected_text"],
        #       mistake_type: note["mistake_type"],
        #       explanation: note["explanation"]
        #   )
        # end

        redirect_to @journal, notice: "添削が完了しました！"
      else
        flash.now[:alert] = "ジャーナルの作成に失敗しました。"
        render :new, status: :unprocessable_entity
      end
    end

  def edit
    @journal = current_user.journals.find(params[:id])
  end

  def update
    @journal = current_user.journals.find(params[:id])
    if @journal.update(journal_params)
      redirect_to journal_path(@journal), success: "ジャーナルが更新されました。"
    else
      flash.now[:alert] = "ジャーナルの更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @journal = current_user.journals.find(params[:id])
    @journal.destroy
    redirect_to journals_path, success: "ジャーナルが削除されました。", status: :see_other
  end

  private
  def journal_params
    params.require(:journal).permit(:title, :posted_date, :mood, :body, :tone)
  end
end
