namespace CodeLab.Models
{
    /// <summary>
    /// One account as an admin sees it. PasswordHash is not filled.
    /// </summary>
    public class AdminUserRow : User
    {
        // How many courses this user teaches
        public int CourseCount { get; set; }

        // True if another table still points at this user, which blocks deleting the account
        public bool HasActivity { get; set; }

        public bool CanSuspend
        {
            get { return Status == UserStatuses.Active; }
        }

        public bool CanReactivate
        {
            get { return Status == UserStatuses.Suspended; }
        }
    }
}
