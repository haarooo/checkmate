package com.example.checkmate.domain.point.service;

import com.example.checkmate.domain.point.dto.PointLedgerResponse;
import com.example.checkmate.domain.point.dto.PointWalletResponse;
import com.example.checkmate.domain.point.entity.LedgerType;
import com.example.checkmate.domain.point.entity.PointLedger;
import com.example.checkmate.domain.point.entity.PointWallet;
import com.example.checkmate.domain.point.repository.PointLedgerRepository;
import com.example.checkmate.domain.point.repository.PointWalletRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PointService {

    private static final long SIGNUP_BONUS_AMOUNT = 100_000L;

    private final PointWalletRepository pointWalletRepository;
    private final PointLedgerRepository pointLedgerRepository;
    private final UserRepository userRepository;

    @Transactional
    public void createInitialWallet(UserEntity user) {
        PointWallet wallet = PointWallet.create(user);
        pointWalletRepository.save(wallet);

        wallet.addBalance(SIGNUP_BONUS_AMOUNT);
        PointLedger ledger = PointLedger.create(
                user, SIGNUP_BONUS_AMOUNT, wallet.getBalance(), LedgerType.SIGNUP_BONUS, "회원가입 보너스");
        pointLedgerRepository.save(ledger);
    }

    @Transactional(readOnly = true)
    public PointWalletResponse getMyWallet(String email) {
        UserEntity user = findUserByEmail(email);
        PointWallet wallet = findWalletByUser(user);
        return new PointWalletResponse(wallet.getBalance());
    }

    @Transactional(readOnly = true)
    public List<PointLedgerResponse> getMyLedgers(String email) {
        UserEntity user = findUserByEmail(email);
        findWalletByUser(user);
        return pointLedgerRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .map(l -> new PointLedgerResponse(
                        l.getId(),
                        l.getAmount(),
                        l.getBalanceAfter(),
                        l.getType().name(),
                        l.getDescription(),
                        l.getCreatedAt()))
                .toList();
    }

    @Transactional
    public PointWalletResponse testCharge(String email, long amount) {
        if (amount <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "충전 금액은 1 이상이어야 합니다.");
        }
        UserEntity user = findUserByEmail(email);
        PointWallet wallet = findWalletByUser(user);

        wallet.addBalance(amount);
        PointLedger ledger = PointLedger.create(
                user, amount, wallet.getBalance(), LedgerType.TEST_CHARGE, "테스트 충전");
        pointLedgerRepository.save(ledger);

        return new PointWalletResponse(wallet.getBalance());
    }

    private UserEntity findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }

    private PointWallet findWalletByUser(UserEntity user) {
        return pointWalletRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "포인트 지갑을 찾을 수 없습니다."));
    }
}