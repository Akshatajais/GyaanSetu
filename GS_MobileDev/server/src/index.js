'use strict'
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import pino from 'pino';
import pinoHttp from 'pino-http';
import quizRoutes from './routes/quiz.routes.js';

dotenv.config();

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('tiny'));
app.use(pinoHttp({ logger }));

app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/quizzes', quizRoutes);

const PORT = process.env.PORT || 4000;
const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  logger.error('MONGODB_URI is not set');
  process.exit(1);
}

mongoose.connect(MONGODB_URI).then(() => {
  logger.info('Connected to MongoDB');
  app.listen(PORT, () => logger.info(`Server started on :${PORT}`));
}).catch((err) => {
  logger.error({ err }, 'Mongo connection failed');
  process.exit(1);
});


