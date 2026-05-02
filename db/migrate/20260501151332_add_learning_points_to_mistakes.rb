class AddLearningPointsToMistakes < ActiveRecord::Migration[7.2]
  def change
    add_column :mistakes, :learning_points, :jsonb, default: {}, null: false
  end
end
