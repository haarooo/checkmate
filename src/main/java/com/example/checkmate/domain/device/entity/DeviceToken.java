package com.example.checkmate.domain.device.entity;

import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "device_tokens")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DeviceToken extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 이 토큰의 현재 소유자.
     * 같은 기기에서 다른 계정으로 로그인하면 user가 교체될 수 있다.
     * token은 기기+앱 인스턴스 기준으로 발급되므로, 소유자를 바꾸는 것이 row를 새로 만드는 것보다 안전하다.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    /**
     * Firebase가 기기별로 발급한 고유 주소.
     * 이 값을 FCM 발송 대상으로 사용하므로 한 token이 두 row에 저장되면 중복 발송이 발생한다.
     * DB UNIQUE 제약으로 중복을 방지하고, 서비스 레이어에서 upsert 방식으로 관리한다.
     * FCM 토큰은 152자 이상 가능하므로 length=512로 충분한 여유를 확보한다.
     */
    @Column(nullable = false, unique = true, length = 512)
    private String token;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DevicePlatform platform;

    /**
     * 로그아웃 시 row를 삭제하지 않고 false로 전환한다.
     * FCM 발송 시 active=true인 token만 조회해 로그아웃된 기기에는 push가 전달되지 않는다.
     * row를 보존하면 재로그인 시 동일 token을 INSERT 없이 UPDATE로 재활성화할 수 있다.
     */
    @Column(nullable = false)
    private boolean active;

    public static DeviceToken create(UserEntity user, String token, DevicePlatform platform) {
        DeviceToken dt = new DeviceToken();
        dt.user = user;
        dt.token = token;
        dt.platform = platform;
        dt.active = true;
        return dt;
    }

    /**
     * 같은 사용자가 동일 token을 재등록할 때 호출한다.
     * 로그아웃 후 재로그인 또는 토큰 갱신 이벤트 시 active를 복구한다.
     */
    public void reactivate(DevicePlatform platform) {
        this.platform = platform;
        this.active = true;
    }

    /**
     * 같은 token이 다른 사용자에게 등록되어 있을 때 현재 로그인 사용자로 교체한다.
     * 409로 거부하면 기기 전환 시 앱이 정상 동작하지 않으므로 재할당을 선택한다.
     * 이후 FCM 발송 대상은 최신 로그인 사용자 기준으로 정리된다.
     */
    public void reassign(UserEntity newUser, DevicePlatform platform) {
        this.user = newUser;
        this.platform = platform;
        this.active = true;
    }

    /** 로그아웃 시 호출. 이 token으로의 FCM 발송이 차단된다. */
    public void deactivate() {
        this.active = false;
    }
}
