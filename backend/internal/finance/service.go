package finance

import (
	"context"
	"strings"
)

type Service struct {
	repository *Repository
}

func NewService(repository *Repository) *Service {
	return &Service{repository: repository}
}

func (s *Service) AddIncome(
	ctx context.Context,
	eventID int64,
	description string,
	amount string,
) (Entry, error) {
	description = strings.TrimSpace(description)
	amount = strings.TrimSpace(amount)

	if err := s.repository.Validate(description, amount); err != nil {
		return Entry{}, err
	}

	return s.repository.AddIncome(ctx, eventID, description, amount)
}

func (s *Service) AddExpense(
	ctx context.Context,
	eventID int64,
	description string,
	amount string,
) (Entry, error) {
	description = strings.TrimSpace(description)
	amount = strings.TrimSpace(amount)

	if err := s.repository.Validate(description, amount); err != nil {
		return Entry{}, err
	}

	return s.repository.AddExpense(ctx, eventID, description, amount)
}

func (s *Service) GetFinancials(
	ctx context.Context,
	eventID int64,
) (Financials, error) {
	return s.repository.GetFinancials(ctx, eventID)
}
