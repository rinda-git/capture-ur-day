class JournalsController < ApplicationController
  helper MistakesHelper
  before_action :authenticate_user!
  def index
    # @journals =current_user.journals.order(created_at: :desc)
    @journals =current_user.journals.includes(:journal_correction).order(posted_date: :desc, id: :desc)
  end

  def show
    @journal = current_user.journals.find(params[:id])
    # @overall = @journal.mistakes.find_by(mistake_type: "overall")
    # @mistake = @journal.mistakes.first
    # @mistakes = @journal.mistakes.where.not(mistake_type: "overall")
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

    # Rails.logger.debug "=== journal_params: #{journal_params.inspect}"
    # 1 フォームから本文の文字列を受け取る
    body = params[:journal][:body]
    tone = params[:journal][:tone]

    raise "tone is nil!" if tone.blank?

# 2 AIへの指示(プロンプト)を作成する

prompt = <<~PROMPT
    You are a bilingual Japanese-English writing teacher and correction coach who helps learners write natural American English and understand grammar clearly in Japanese.
    Your job is to REWRITE the user's message into natural, emotionally authentic American English without changing the original meaning.
    After each grammar correction, teach grammar formula / pattern and a tip.
    If the mistake is related to tense, present perfect, prepositions, gerunds, infinitives, or word order:

    Always explain:
    1. Basic grammar rule
    2. Why it applies here
    3. Corrected example
    4. Short learning tip
    If the user uses unnatural phrasing, explain the more natural expression.

    ====================
    TASK
    ====================
    Rewrite the user's text into natural American English, then provide corrections and feedback.

    Tone: #{tone}
    - polite:#{'  '}
    Calm, thoughtful, emotionally mature natural American English.
    Kind, steady, and respectful.
    Slightly polished, but still simple and human.
    Use everyday vocabulary, not formal or fancy words.
    Gentle emotional restraint.
    Longer smooth sentences are okay.
    Reserved emotional tone.

    - standard:
    Warm, natural everyday American English.
    Honest, balanced, believable.
    Like a real native American writing privately.
    Default natural tone.

    - casual:
    Warm, relaxed, conversational natural American English.
    More spontaneous and emotionally close.
    Use simple wording and natural flow.
    Simple wording should not oversimplify meaning.
    More immediate and human.

    The user may write in Japanese or English.

    ====================
    REWRITE RULES
    ====================
    Important:
    - Preserve the original meaning, emotional nuance, and timeline.
    - corrected_text must be natural American English first.
    - Do NOT translate literally or preserve awkward wording
    - Do not over-specify what is only implied.
    - If the original text is vague, keep it naturally vague.
    - Do not over-specify implied information
    - Rewrite into natural American English a real person would use.
    - Understand Japanese nuance deeply before rewriting into natural American English.
    - If the text is in Japanese, follow the flow of the original Japanese writing and rewrite the intended meaning into natural American English.

    ====================
    CORRECTION RULES
    ====================
    - Return 3 to 5 notes for short input.
    - Return 5 to 7 notes for longer input when there are enough useful learning points.

    Do not only return the most serious mistakes.
    Include useful learning points from grammar, word choice, spelling, sentence structure, and natural expression.
    Each note should cover one specific learning point.
    Do not combine multiple unrelated issues into one note
    For each mistake, provide:
    - original_text
    - corrected_text
    - mistake_type: grammar | spelling | word_choice | expression | translation
    - explanation (in Japanese)
      First explain what is grammatically missing or unnatural in the original text.
      Then explain the reusable English pattern used in the correction.
      Avoid explanations that only describe sentence flow, tone, or readability.
    - learning_points:
      - label: short Japanese label for the learning point
      - pattern:#{' '}
        reusable English grammar pattern or phrase pattern
        Do not return overly broad patterns such as "in + noun", "with + noun", or "to + verb" unless that broad pattern is the main learning point.
        The pattern should be specific enough to make a new sentence.
      - review_tag: short lowercase English tag for review, such as preposition, tense, article, word_order, collocation, infinitive, gerund, expression, translation

    Grammar explanations should be practical:
    Explain the reusable grammar rule behind each mistake or show common and frequently used collocation patterns not only the correction.
    ✓ Good: 「前置詞：『部屋へ行く』は go to + place を使います」具体例を出し、使う組み合わせを提示する。
    ✓ Good: 「基本ルール：when it comes to + 名詞 / 動名詞」この表現の to は不定詞ではなく前置詞です。そのため後ろに動詞の原形 write は置けず、動名詞 writing を使います。
    ✗ Bad: 「文法的に誤りがあります」

    Classification rules:
    - mistake_type must be exactly one of: grammar, spelling, word_choice, expression, translation

    ====================
    learning_points RULES
    ====================
      For learning_points.pattern:
      Learning point selection priority:
      1. Choose the most useful reusable phrase, collocation, or grammar pattern from corrected_text.
      2. Prefer expressions learners can reuse in daily journaling.
      3. Do not choose a basic grammar rule if corrected_text contains a more useful natural expression.
      4. The pattern must be based on corrected_text, but do not make corrected_text unnatural just to match the pattern.
      5. The pattern should be the smallest reusable unit that preserves the main meaning.

      Related phrases:
      - Return related_phrases only for the 2 most useful learning_points.
      - For other notes, return related_phrases: [].
      - related_phrases must be semantic alternatives to learning_points.pattern, not examples of the same pattern.
      - phrase must be a reusable phrase pattern, not a full sentence.
      - example must be a complete sentence using that phrase.
    #{'  '}

      Classification rules:
      - mistake_type must be exactly one of: grammar, spelling, word_choice, expression, translation.
      - Use detailed categories such as tense, preposition, article, word_order, collocation, infinitive, gerund only in
      learning_points.review_tag.

        Only create a note when it teaches a useful reusable point for the learner.

      ====================
      LEARNING POINT SELECTION
      ====================

      Only create a note when it teaches a useful reusable point for the learner.

      Priority:
      1. Naturalness first: corrected_text must sound natural, emotionally authentic, and not overly formal.
      2. Prefer useful collocations and natural expressions over basic grammar frames.
      3. Choose patterns the learner can reuse for emotions, self-reflection, relationships, habits, worries, personal growth, and nuanced feelings.
      4. Do not create a note for a change that is only a tiny style preference.
      5. Do not replace a natural casual expression with a more formal one unless the selected tone requires it.
      6. learning_points.pattern must be based on a natural phrase in corrected_text.
      7. The pattern should be the smallest reusable unit that preserves the main meaning, but not overly generic or beginner-level.
      8. The grammar placeholder in phrase and pattern must match the example sentence, such as + 名詞, + 動名詞, + to + 動詞, or + 主語 + 動詞.

      Bad learning points:
      - "I have many + 名詞"
      - "I don't usually + 動詞 + with others"
      - "often + feel + 動詞"
      - "remove unnecessary words"

      Good learning points:
      - "insecurities about + 名詞"
      - "share my feelings with + 人"
      - "It often feels like + 主語 + 動詞"
      - "have mixed feelings about + 名詞"

    ====================
    INPUT
    ====================
      Input text:
      "#{body}"

    ====================
    OUTPUT JSON ONLY
    ====================
      Do not omit any keys.
      Return ONLY valid JSON matching this exact structure:
      {
        "rewritten_text": "text (required)",
        "notes":[
          {
            "original_text": "string (required)",
            "corrected_text": "string (required)",
            "mistake_type": "grammar, spelling, word_choice, expression or translation (required)",
            "explanation": "text in Japanese (required)",
            "learning_points": {
              "label": "短い日本語ラベル。例: 前置詞 to の抜け 動詞の形 語彙選択など",
              "pattern": "再利用できる英語の型。例: find it hard to + 動詞 + in that kind of environmentという形",
              "meaning": "この表現の意味やニュアンス。例: 〜に対して感謝している",
              "review_tag": "復習用の短い英語タグ。例: preposition",
              "related_phrases":[
              {
               "phrase": "似たようなネイティブが使う自然な表現",
               "meaning": "その表現の意味やニュアンスを日本語で説明",
               "example": "完全な英語例文。"
              },
              {
               "phrase": "似たようなネイティブが使う自然な表現",
               "meaning": "その表現の意味やニュアンスを日本語で説明",
                "example": "完全な英語例文。"
               }
              ]
            }
          }
        ]
      }

      If the input contains Japanese text, classify all rewriting choices as "translation" type.
      For each translation note, explain in Japanese why the specific English word or phrase was chosen to express the original Japanese nuance.
      english_feedback must be based only on THIS text.Be practical, modest, and helpful.
      If there are no notes, return "notes": []
      PROMPT

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
