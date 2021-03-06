//
//  CommonTypes.h
//  SimEpidemic
//
//  Created by Tatsuo Unemi on 2020/05/05.
//  Copyright © 2020 Tatsuo Unemi. All rights reserved.
//

typedef enum {
	Susceptible, Asymptomatic, Symptomatic, Recovered, Died,
	QuarantineAsym, QuarantineSymp,
	NStateIndexes,
	NHealthTypes = QuarantineAsym,
} HealthType;

typedef enum {
	TestTotal,
	TestAsSymptom, TestAsContact, TestAsSuspected,
	TestPositive, TestNegative,
	TestPositiveRate,
	NAllTestTypes
} TestType;

#define NIntTestTypes TestPositiveRate
#define NIntIndexes (NStateIndexes+NIntTestTypes)
#define NAllIndexes (NStateIndexes+NAllTestTypes)

typedef enum {
	WarpInside, WarpToHospital, WarpToCemeteryF, WarpToCemeteryH, WarpBack
} WarpType;

typedef struct {
	CGFloat min, max, mode;
} DistInfo;

typedef struct {
	CGFloat infec, infecDst; // infection probability and distance
	CGFloat dstST, dstOB; // Distancing strength and obedience
	CGFloat mobFr; // Mobility frequency
	CGFloat cntctTrc; // Contact tracing
	CGFloat tstDelay, tstProc, tstInterval, tstSens, tstSpec; // test delay, process, interval, sensitivity, and specificity
	CGFloat tstSbjAsy, tstSbjSym; // Subjects for test of asymptomatic, and symptomatic. contacts are tested 100%.
	DistInfo mobDist; // and distance
	DistInfo incub, fatal, recov, immun; // incubation, fatality, recovery, immunity
	NSInteger step;
} RuntimeParams;
typedef struct {
	NSInteger initPop, worldSize, mesh, nInitInfec, stepsPerDay;
} WorldParams;

#define PARAM_F1 infec
#define PARAM_D1 mobDist
#define PARAM_I1 initPop

typedef struct StatDataRec {
	struct StatDataRec *next;
	NSUInteger cnt[NIntIndexes];
	CGFloat pRate;
} StatData;

typedef struct TestEntryRec {
	struct TestEntryRec *prev, *next;
	NSInteger timeStamp;
	BOOL isPositive;
	struct AgentRec *agent;
} TestEntry;

typedef struct ContactInfoRec {
	struct ContactInfoRec *prev, *next;
	NSInteger timeStamp;
	struct AgentRec *agent;
} ContactInfo;

typedef struct AgentRec {
	NSInteger ID;
	struct AgentRec *prev, *next;
	CGFloat app, prf, x, y, vx, vy, fx, fy;
	CGPoint orgPt;
	CGFloat daysInfected, daysDiseased;
	CGFloat daysToRecover, daysToOnset, daysToDie, imExpr;
	HealthType health, newHealth;
	BOOL distancing, isOutOfField, isWarping, gotAtHospital;
	NSInteger lastTested;
	struct AgentRec *best;
	CGFloat bestDist;
	ContactInfo *contactInfoHead, *contactInfoTail;
} Agent;
