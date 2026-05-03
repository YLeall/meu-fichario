from apscheduler.schedulers.background import BackgroundScheduler
from services.installment_service import update_overdue


def start_scheduler():
    scheduler = BackgroundScheduler(timezone="America/Bahia")
    scheduler.add_job(update_overdue, "cron", hour=6, minute=0)
    scheduler.start()
