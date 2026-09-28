import mongoose from 'mongoose';

const ResponseItemSchema = new mongoose.Schema({
  questionId: { type: String, required: true },
  selectedIndex: { type: Number, required: true },
  isCorrect: { type: Boolean, required: false }
}, { _id: false });

const QuizResponseSchema = new mongoose.Schema({
  quizId: { type: String, required: true, index: true },
  studentId: { type: String, required: true, index: true },
  responses: { type: [ResponseItemSchema], required: true },
  completed: { type: Boolean, default: false }
}, { timestamps: true });

QuizResponseSchema.index({ quizId: 1, studentId: 1 }, { unique: true });

export default mongoose.model('QuizResponse', QuizResponseSchema);


