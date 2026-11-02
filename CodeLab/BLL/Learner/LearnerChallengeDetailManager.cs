using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CodeLab.DAL;
using CodeLab.Models;
using CodeLab.Services;

namespace CodeLab.BLL
{
    public sealed class LearnerChallengeDetailManager
    {
        private readonly LearnerChallengeDetailRepository repository =
            new LearnerChallengeDetailRepository();

        private readonly JDoodleExecutionService executionService =
            new JDoodleExecutionService();

        public LearnerChallengeDetail GetChallenge(
            int learnerId,
            int challengeId)
        {
            ValidateIds(learnerId, challengeId);

            return repository.GetChallenge(learnerId, challengeId);
        }

        public List<LearnerChallengeSubmission> GetSubmissions(
            int learnerId,
            int challengeId)
        {
            ValidateIds(learnerId, challengeId);

            return repository.GetSubmissions(learnerId, challengeId);
        }

        public async Task<ChallengeSubmissionResult> SubmitAsync(
            int learnerId,
            int challengeId,
            string submittedCode)
        {
            ValidateIds(learnerId, challengeId);

            if (string.IsNullOrWhiteSpace(submittedCode))
            {
                return NotSaved("Enter some code before submitting.");
            }

            if (submittedCode.Length > 20000)
            {
                return NotSaved(
                    "Your code is too long. The limit is 20,000 characters.");
            }

            try
            {
                // Load the language and expected output from the database.
                // Neither value comes from the browser.
                var challenge = repository.GetChallenge(
                    learnerId,
                    challengeId);

                if (challenge == null)
                {
                    return NotSaved(
                        "This challenge is unavailable. You must have completed " +
                        "its published course.");
                }

                bool markup = IsMarkupChallenge(challenge.Language);
                CodeExecutionResult execution = markup
                    ? new CodeExecutionResult {
                        RequestSucceeded = true,
                        Output = "HTML/CSS source review. No console execution or automated visual test was performed."
                    }
                    : await executionService.ExecuteAsync(challenge.Language, submittedCode);

                // Service failures must not count as learner attempts.
                if (!execution.RequestSucceeded)
                {
                    return NotSaved(execution.ErrorMessage);
                }

                // Check access and challenge changes after execution.
                var latestChallenge = repository.GetChallenge(
                    learnerId,
                    challengeId);

                if (latestChallenge == null)
                {
                    return NotSaved(
                        "Your access to this challenge changed during execution. " +
                        "The submission was not saved.",
                        execution.Output);
                }

                if (!string.Equals(
                        challenge.Language,
                        latestChallenge.Language,
                        StringComparison.Ordinal) ||
                    !string.Equals(
                        challenge.ExpectedOutput,
                        latestChallenge.ExpectedOutput,
                        StringComparison.Ordinal) ||
                    !string.Equals(
                        challenge.Description,
                        latestChallenge.Description,
                        StringComparison.Ordinal) ||
                    challenge.PointsReward != latestChallenge.PointsReward)
                {
                    return NotSaved(
                        "The challenge changed during execution. " +
                        "Refresh the page before submitting again.",
                        execution.Output);
                }

                string actualOutput = execution.Output ?? string.Empty;

                bool matches = markup || string.Equals(
                    NormaliseOutput(actualOutput),
                    NormaliseOutput(challenge.ExpectedOutput),
                    StringComparison.Ordinal);

                var review = await new GeminiCodeReviewService().EvaluateAsync(challenge,submittedCode,actualOutput,markup?"Source review only":matches?"Passed":"Failed");
                string status = GeminiCodeReviewService.FinalStatus(matches,review);
                var reviewedChallenge=repository.GetChallenge(learnerId,challengeId);
                if(reviewedChallenge==null || reviewedChallenge.Description!=challenge.Description || reviewedChallenge.ExpectedOutput!=challenge.ExpectedOutput || reviewedChallenge.Language!=challenge.Language || reviewedChallenge.PointsReward!=challenge.PointsReward)
                    return NotSaved("The challenge or your access changed during review. Refresh and submit again.",actualOutput);

                // The repository saves the attempt and awards first-pass XP
                // together in one database transaction.
                var saved = repository.SaveSubmission(
                    learnerId,
                    challengeId,
                    submittedCode,
                    status,
                    actualOutput, review.Feedback);
                if(saved.Saved) saved.AiFeedback = review.Feedback;
                return saved;
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Challenge submission could not be confirmed: {0}", ex);

                // A lost connection during commit can make the outcome
                // uncertain. Do not automatically repeat the submission.
                return NotSaved(
                    "We could not confirm that your submission was saved. " +
                    "Refresh and check your submission history before trying again.");
            }
        }

        public static bool IsMarkupChallenge(string language)
        {
            return string.Equals((language ?? "").Trim(), "html", StringComparison.OrdinalIgnoreCase);
        }

        private static string NormaliseOutput(string value)
        {
            return (value ?? string.Empty)
                .Replace("\r\n", "\n")
                .Replace("\r", "\n")
                .TrimEnd('\n');
        }

        private static ChallengeSubmissionResult NotSaved(
            string message,
            string output = "")
        {
            return new ChallengeSubmissionResult
            {
                Saved = false,
                SubmissionId = null,
                Status = string.Empty,
                Output = output ?? string.Empty,
                PointsAwarded = 0,
                ErrorMessage = message
            };
        }

        private static void ValidateIds(int learnerId, int challengeId)
        {
            if (learnerId <= 0)
            {
                throw new ArgumentException(
                    "Invalid learner ID.",
                    nameof(learnerId));
            }

            if (challengeId <= 0)
            {
                throw new ArgumentException(
                    "Invalid challenge ID.",
                    nameof(challengeId));
            }
        }
    }
}