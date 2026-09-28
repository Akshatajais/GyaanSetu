import Quiz from '../models/Quiz.js';
import QuizResponse from '../models/QuizResponse.js';

export async function getQuiz(req, res) {
  try {
    const { quizId } = req.params;
    const quiz = await Quiz.findOne({ quizId, isActive: true }).lean();
    if (!quiz) return res.status(404).json({ message: 'Quiz not found' });
    return res.json({
      quizId: quiz.quizId,
      title: quiz.title,
      questions: quiz.questions.map(q => ({
        questionId: q.questionId,
        prompt: q.prompt,
        options: q.options.map(o => o.text)
      }))
    });
  } catch (e) {
    return res.status(500).json({ message: 'Failed to fetch quiz' });
  }
}

export async function upsertResponse(req, res) {
  try {
    const { quizId } = req.params;
    const { studentId, questionId, selectedIndex } = req.body;
    if (!studentId || !questionId || selectedIndex === undefined) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const quiz = await Quiz.findOne({ quizId }).lean();
    if (!quiz) return res.status(404).json({ message: 'Quiz not found' });
    const question = quiz.questions.find(q => q.questionId === questionId);
    if (!question) return res.status(400).json({ message: 'Invalid questionId' });

    const isCorrect = typeof question.correctIndex === 'number' ? question.correctIndex === selectedIndex : undefined;

    const doc = await QuizResponse.findOneAndUpdate(
      { quizId, studentId },
      { $setOnInsert: { quizId, studentId }, $set: { updatedAt: new Date() }, $pull: { responses: { questionId } } },
      { upsert: true, new: true }
    );

    doc.responses.push({ questionId, selectedIndex, isCorrect });
    await doc.save();

    return res.json({ message: 'Saved', isCorrect });
  } catch (e) {
    return res.status(500).json({ message: 'Failed to save response' });
  }
}

export async function markComplete(req, res) {
  try {
    const { quizId } = req.params;
    const { studentId } = req.body;
    if (!studentId) return res.status(400).json({ message: 'Missing studentId' });

    const doc = await QuizResponse.findOneAndUpdate(
      { quizId, studentId },
      { $set: { completed: true } },
      { new: true }
    );

    if (!doc) return res.status(404).json({ message: 'No responses found' });

    const total = doc.responses.length;
    const correct = doc.responses.filter(r => r.isCorrect === true).length;

    return res.json({ message: 'Completed', total, correct, percentage: total ? Math.round((correct/total)*100) : 0 });
  } catch (e) {
    return res.status(500).json({ message: 'Failed to mark complete' });
  }
}


