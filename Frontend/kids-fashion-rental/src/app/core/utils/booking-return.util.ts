export interface ReturnCalcResult {
  scheduledReturn: string;
  isEarly: boolean;
  isLate: boolean;
  extraDays: number;
  lateCharge: number;
  damageDeduction: number;
  refundAmount: number;
  maxDamage: number;
}

function toDateOnly(iso: string): Date {
  const d = new Date(iso);
  d.setHours(0, 0, 0, 0);
  return d;
}

/** Refund = deposit − late charge − damage deduction from deposit */
export function computeReturnRefund(
  deposit: number,
  scheduledReturn: string,
  actualReturn: string,
  extraChargePerDay: number,
  damageDeduction: number
): ReturnCalcResult {
  const sched = toDateOnly(scheduledReturn);
  const actual = toDateOnly(actualReturn);
  const isEarly = actual < sched;
  const isLate = actual > sched;
  let extraDays = 0;
  let lateCharge = 0;
  if (isLate) {
    extraDays = Math.ceil((actual.getTime() - sched.getTime()) / 86400000);
    lateCharge = extraDays * extraChargePerDay;
  }
  const maxDamage = Math.max(0, deposit - lateCharge);
  const damage = Math.min(Math.max(0, damageDeduction), maxDamage);
  const refundAmount = Math.max(0, deposit - lateCharge - damage);
  return {
    scheduledReturn,
    isEarly,
    isLate,
    extraDays,
    lateCharge,
    damageDeduction: damage,
    refundAmount,
    maxDamage
  };
}
