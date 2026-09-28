import { Router } from 'express';
import { getQuiz, upsertResponse, markComplete } from '../controllers/quiz.controller.js';

const router = Router();

router.get('/:quizId', getQuiz);
router.post('/:quizId/respond', upsertResponse);
router.post('/:quizId/complete', markComplete);

export default router;


