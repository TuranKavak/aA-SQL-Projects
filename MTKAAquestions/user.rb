require_relative 'questions_database'
require_relative 'question'
require_relative 'question_follow'
require_relative 'question_like'
require_relative 'reply'
#require_relative 'model_base'

class User < ModelBase

  def self.find_by_name(fname, lname)#tamam
    attrs = { fname: fname, lname: lname }
    user_data = QuestionsDatabase.get_first_row(<<-SQL, attrs)
      SELECT
        users.*
      FROM
        users
      WHERE
        users.fname = :fname AND users.lname = :lname
    SQL

    user_data.nil? ? nil : User.new(user_data)
  end

  def self.find_by_id(id)#tamam
    user_data = QuestionsDatabase.get_first_row(<<-SQL, id: id)
        SELECT
          users.*
        FROM
          users
        WHERE
          users.id = :id
    SQL
    user_data.nil? ? nil : User.new(user_data)
  end

  attr_reader :id
  attr_accessor :fname, :lname

  def initialize(options = {})#tamam
    @id, @fname, @lname = options.values_at('id', 'fname', 'lname')
  end

  def attrs#tamam
    { fname: fname, lname: lname }
  end

  def authored_questions#tamam
    Question.find_by_author_id(id)
  end

  def followed_questions#tamam
    QuestionFollow.followed_questions_for_user_id(id)
  end

  def authored_replies#tamam
    Reply.find_by_user_id(id)
  end

  def liked_questions#tamam
    QuestionLike.liked_questions_for_user_id(id)
  end

  def save
    if @id
      QuestionsDatabase.execute(<<-SQL, attrs.merge({ id: id }))
        UPDATE
          users
        SET
          fname = :fname, lname = :lname
        WHERE
          users.id = :id
      SQL
    else
      QuestionsDatabase.execute(<<-SQL, attrs)
        INSERT INTO
          users (fname, lname)
        VALUES
          (:fname, :lname)
      SQL

      @id = QuestionsDatabase.last_insert_row_id
    end
    self
  end

  def average_karma
    QuestionsDatabase.get_first_value(<<-SQL, author_id: self.id)
      SELECT
        CAST(COUNT(question_likes.id) AS FLOAT) / COUNT(DISTINCT(questions.id)) AS avg_karma
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        questions.id = question_likes.question_id
      WHERE
        questions.author_id = :author_id
    SQL

  end



end