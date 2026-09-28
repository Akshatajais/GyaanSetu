import mongoose from 'mongoose';

const OptionSchema = new mongoose.Schema({
  text: { type: String, required: true }
}, { _id: false });

const QuestionSchema = new mongoose.Schema({
  prompt: { type: String, required: true },
  options: { type: [OptionSchema], required: true },
  correctIndex: { type: Number, required: false },
  questionId: { type: String, required: true }
}, { _id: false });

const QuizSchema = new mongoose.Schema({
  quizId: { type: String, required: true, unique: true, index: true },
  title: { type: String, required: true },
  questions: { type: [QuestionSchema], required: true },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

export default mongoose.model('Quiz', QuizSchema);


