package dashboard

type Event struct {
	ID            int64  `json:"id"`
	Title         string `json:"title"`
	EventDate     string `json:"event_date"`
	Venue         string `json:"venue"`
	GuestCount    int    `json:"guest_count"`
	Status        string `json:"status"`
	TotalIncome   string `json:"total_income"`
	TotalExpenses string `json:"total_expenses"`
	Profit        string `json:"profit"`
}

type Summary struct {
	From           string  `json:"from"`
	To             string  `json:"to"`
	EventCount     int     `json:"event_count"`
	UpcomingCount  int     `json:"upcoming_count"`
	RunningCount   int     `json:"running_count"`
	CompletedCount int     `json:"completed_count"`
	TotalIncome    string  `json:"total_income"`
	TotalExpenses  string  `json:"total_expenses"`
	Profit         string  `json:"profit"`
	Events         []Event `json:"events"`
}
