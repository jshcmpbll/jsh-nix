from finvizfinance.quote import finvizfinance

def get_analyst_recommendation(ticker: str):
    stock = finvizfinance(ticker)
    rec = stock.ticker_fundament()['Recom']
    return rec

def main():
    import sys
    if len(sys.argv) < 2:
        print("Usage: finvizrec <TICKER>")
        sys.exit(1)
    rec = get_analyst_recommendation(sys.argv[1])
    message = f"\nAnalyst recommendations for {sys.argv[1]}: {rec}"
    print(message)

if __name__ == "__main__":
    main()
